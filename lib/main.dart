import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/app_startup_service.dart';
import 'utils/app_logger.dart';
import 'widgets/crash_dialog.dart';
import 'providers/cart_provider.dart';

// Global key for the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey _appKey = GlobalKey();

class _AppWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    try {
      if (await windowManager.isPreventClose()) return;
      
      // Check for unsigned transactions
      final hasUnsigned = await _hasUnsignedTransactions();
      if (hasUnsigned) {
        final shouldClose = await _showCloseConfirmation();
        if (shouldClose != true) {
          return;
        }
      }
      windowManager.destroy();
    } catch (e) {
      // If there's an error checking, allow close
      debugPrint('Error checking unsaved transactions: $e');
      windowManager.destroy();
    }
  }

  Future<bool> _hasUnsignedTransactions() async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return false;
      
      // Try to get CartProvider safely
      try {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        return !cartProvider.isEmpty;
      } catch (e) {
        // If CartProvider not available, assume no transactions
        debugPrint('CartProvider not available: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking unsigned transactions: $e');
      return false;
    }
  }

  Future<bool?> _showCloseConfirmation() async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return false;
      
      return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Unsigned Transactions'),
          content: const Text('You have items in your cart. Are you sure you want to close?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Close Anyway'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error showing close confirmation: $e');
      return true; // Default to close if error
    }
  }
}

Future<void> _showCrashDialog(Object error, StackTrace stackTrace) async {
  try {
    final errorCode = error.toString().split('\n').first.trim();
    await AppLogger().log('Unhandled error: $errorCode\n$stackTrace');
    
    if (kDebugMode) {
      debugPrint('Unhandled error: $error\n$stackTrace');
    }
    
    // Wait a bit for the UI to be ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      await CrashDialog.show(
        context,
        errorCode: errorCode,
        message: '$error',
      );
    }
  } catch (e) {
    // If we can't show the dialog, at least print the error
    debugPrint('Failed to show crash dialog: $e');
    debugPrint('Original error: $error');
    debugPrint('Stack trace: $stackTrace');
  }
}

Future<void> _handleFlutterError(FlutterErrorDetails details) async {
  try {
    await AppLogger().log(
      'Flutter error: ${details.exceptionAsString()}\n${details.stack}',
    );
    
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
    
    // Wait a bit for the UI to be ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      await CrashDialog.show(
        context,
        errorCode: details.exception.toString().split('\n').first.trim(),
        message: details.exceptionAsString(),
      );
    }
  } catch (e) {
    debugPrint('Failed to handle Flutter error: $e');
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  }
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger early
  try {
    await AppLogger().init();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Logger init failed: $e');
    }
  }

  // Set up error handlers AFTER logger is initialized
  FlutterError.onError = (details) {
    // Don't await here to prevent blocking
    _handleFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    // Don't await here to prevent blocking
    _showCrashDialog(error, stackTrace);
    return true;
  };

  // Run the app with error zone
  await runZonedGuarded<Future<void>>(
    () async {
      // Initialize app
      runApp(MyApp(key: _appKey));

      // Post-frame initialization
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _initializeApp();
        } catch (e, stackTrace) {
          debugPrint('App initialization failed: $e');
          debugPrint('Stack trace: $stackTrace');
          await AppLogger().log('App initialization failed: $e\n$stackTrace');
        }
      });
    },
    (error, stackTrace) async {
      // Handle any uncaught errors
      await _showCrashDialog(error, stackTrace);
    },
  );
}

Future<void> _initializeApp() async {
  // Initialize database first
  try {
    final dbService = DatabaseService();
    if (!dbService.isInitialized) {
      await dbService.init().timeout(const Duration(seconds: 15));
    }
    await AppLogger().log('Database initialized successfully');
  } catch (e) {
    await AppLogger().log('Database initialization failed: $e');
    // Don't rethrow - allow app to continue with limited functionality
  }

  // Initialize startup service
  try {
    final startupService = AppStartupService();
    await startupService.init().timeout(const Duration(seconds: 10));
    await AppLogger().log('Startup service initialized successfully');
  } catch (e) {
    await AppLogger().log('Startup service init failed: $e');
    // Don't rethrow - allow app to continue with limited functionality
  }

  // Initialize CartProvider - this will use the singleton
  try {
    await CartProvider.ready.timeout(const Duration(seconds: 10));
    await AppLogger().log('CartProvider initialized successfully');
  } catch (e) {
    await AppLogger().log('CartProvider init failed: $e');
    // Don't rethrow - allow app to continue with limited functionality
  }

  await AppLogger().log('App started');

  // Window management for desktop
  if (!kIsWeb) {
    try {
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(1280, 720),
        center: true,
        minimumSize: Size(1024, 600),
        title: 'Plexus',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      // Use a single window listener instance
      final windowListener = _AppWindowListener();
      windowManager.addListener(windowListener);
      
      // Store reference to prevent garbage collection
      // You might want to store this in a static list or variable
    } catch (e) {
      await AppLogger().log('Window manager initialization failed: $e');
      debugPrint('Window manager error: $e');
    }
  }
}