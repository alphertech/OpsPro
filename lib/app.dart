import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';
import 'mixins/route_aware_mixin.dart';
import 'providers/security_provider.dart';
import 'providers/product_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/accounting_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/purchase_order_provider.dart';
import 'providers/project_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/system_health_provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/lock_type_selection_screen.dart';
import 'screens/auth/security_setup_screen.dart';
import 'screens/auth/lock_screen.dart';
import 'services/app_startup_service.dart';
import 'services/navigation_service.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FocusNode _f5FocusNode = FocusNode();
  bool _lockRequested = false;
  SecurityProvider? _security;
  bool _securityInitialized = false;
  bool _cartRestoreChecked = false;
  bool _appInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _f5FocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _f5FocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.f5 &&
        !_lockRequested) {
      _lockRequested = true;
      final security = _security;
      if (security != null && security.isAuthenticated && !security.isSessionLocked) {
        security.lockSession();
        NavigationService.navigateTo('/lock');
      }
      Future.delayed(const Duration(seconds: 1), () => _lockRequested = false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _initializeApp() async {
    // Prevent multiple initialization attempts
    if (_appInitialized) return;
    _appInitialized = true;

    try {
      final security = _security;
      if (security != null && !security.isReady) {
        await security.init().timeout(const Duration(seconds: 15));
      }
      
      // Don't call CartProvider.init() here - it's already created by Provider
      // Just wait for it to be ready
      try {
        await CartProvider.ready.timeout(const Duration(seconds: 10));
        debugPrint('CartProvider is ready');
      } catch (e) {
        debugPrint('CartProvider ready check failed: $e');
        // CartProvider will still work, just without persistence
      }
      
      debugPrint('App initialization completed');
    } catch (e) {
      debugPrint('App initialization failed: $e');
      _appInitialized = false; // Allow retry
    }
  }

  Future<void> _checkCartRestore() async {
    if (_cartRestoreChecked) return;
    _cartRestoreChecked = true;

    // Wait a moment for the UI to be fully ready
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final context = NavigationService.navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        debugPrint('Context not available for cart restore');
        return;
      }

      // Check if cart provider is available
      final cart = context.read<CartProvider>();

      if (!cart.hasUnfinishedCart) {
        debugPrint('No unfinished cart to restore');
        return;
      }

      final security = context.read<SecurityProvider>();
      if (!security.isAuthenticated) {
        debugPrint('User not authenticated for cart restore');
        return;
      }

      final shouldRestore = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Restore previous session?'),
          content: const Text(
            'You have items in your cart from a previous session. '
            'Would you like to restore them?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (shouldRestore != true && mounted) {
        cart.clear();
        debugPrint('Cart cleared');
      } else {
        debugPrint('Cart restored');
      }
    } catch (e) {
      debugPrint('Error checking cart restore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final provider = SecurityProvider();
          _security = provider;
          return provider;
        }),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => AccountingProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseOrderProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyTaxProvider()),
        ChangeNotifierProvider(create: (_) => AuditProvider()),
        ChangeNotifierProvider(create: (_) => SystemHealthProvider()),
        ChangeNotifierProvider(create: (_) => RecurringInvoiceProvider()),
        ChangeNotifierProvider(create: (_) => WarehouseProvider()),
        ChangeNotifierProvider(create: (_) => CommunicationProvider()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<SecurityProvider>(
        builder: (context, security, _) {
          // Initialize app only once
          if (!_securityInitialized) {
            _securityInitialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeApp().catchError((e) {
                debugPrint('App initialization failed: $e');
              });
            });
          }

          // Check for cart restore after authentication
          if (security.isAuthenticated && !_cartRestoreChecked) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _checkCartRestore());
          }

          return MaterialApp(
            title: 'Plexus',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            navigatorKey: NavigationService.navigatorKey,
            navigatorObservers: [routeObserver],
            onGenerateRoute: AppRoutes.generateRoute,
            home: Focus(
              focusNode: _f5FocusNode,
              autofocus: true,
              onKeyEvent: _onKey,
              child: const _SecurityGate(),
            ),
            builder: (context, child) {
              return child!;
            },
          );
        },
      ),
    );
  }
}

class _SecurityGate extends StatefulWidget {
  const _SecurityGate();

  @override
  State<_SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<_SecurityGate> {
  final AppStartupService _startup = AppStartupService();
  bool _initChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _initChecked = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      final security = context.watch<SecurityProvider>();

      // Show splash screen while security provider is initializing
      if (!_initChecked) {
        return const _SplashScreen();
      }

      if (security.isFirstRun || !security.isSetupComplete) {
        return const SecuritySetupScreen();
      }

      // Check lock type
      if (security.isAuthenticated && security.currentUser?.lockType == null) {
        return const LockTypeSelectionScreen();
      }

      // Dashboard for authenticated users
      if (security.isAuthenticated) {
        if (!_startup.isLoggedIn) {
          final userId = security.currentUser?.id;
          if (userId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _startup.markLogin(userId);
            });
          }
        }
        return const DashboardScreen();
      }

      // Lock screen for locked sessions
      if (security.isSessionLocked) {
        return const LockScreen();
      }

      // Login screen
      return const LoginScreen();
      
    } catch (e) {
      // Fallback error screen
      debugPrint('Security gate error: $e');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'An error occurred',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Please restart the application',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Try to recover by forcing a rebuild
                  setState(() {});
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}