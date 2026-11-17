import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../config/app_theme.dart';
import '../../widgets/pattern_lock_widget.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';
  String _pattern = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final security = context.read<SecurityProvider>();
    final lockType = security.lockType ?? 'password';
    bool success = false;

    if (lockType == 'password') {
      success = await security.unlockSession(_passwordController.text.trim(), type: 'password');
    } else if (lockType == 'pin') {
      success = await security.unlockSession(_pinController.text.trim(), type: 'pin');
    } else if (lockType == 'pattern') {
      success = await security.unlockSession(_pattern, type: 'pattern');
    }

    if (success) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session unlocked successfully.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } else if (mounted) {
      setState(() {
        _errorMessage = security.errorMessage ?? 'Invalid credentials. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final security = context.watch<SecurityProvider>();
    final lockType = security.lockType ?? 'password';

    String title = 'Session Locked';
    String subtitle = 'Authenticate to continue';

    if (lockType == 'password') {
      title = 'Session Locked';
      subtitle = 'Enter your password to continue';
    } else if (lockType == 'pin') {
      title = 'Session Locked';
      subtitle = 'Enter your PIN to continue';
    } else if (lockType == 'pattern') {
      title = 'Session Locked';
      subtitle = 'Draw your pattern to continue';
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.inverseSurface,
        body: Center(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(CupertinoIcons.lock, size: 28, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (lockType == 'password')
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      prefixIcon: CupertinoIcons.lock,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                      onSubmitted: (_) => _unlock(),
                    )
                  else if (lockType == 'pin')
                    CustomTextField(
                      controller: _pinController,
                      label: 'PIN',
                      prefixIcon: CupertinoIcons.lock,
                      obscureText: true,
                      hint: '••••••',
                      keyboardType: TextInputType.number,
                      errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                      onSubmitted: (_) => _unlock(),
                    )
                  else if (lockType == 'pattern')
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: PatternLockWidget(
                            size: 200,
                            selectedColor: theme.colorScheme.primary,
                            onPatternComplete: (pattern) {
                              setState(() => _pattern = pattern);
                              Future.delayed(const Duration(milliseconds: 400), _unlock);
                            },
                          ),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_errorMessage, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                          ),
                      ],
                    ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      label: _isLoading ? 'Unlocking...' : 'Unlock',
                      icon: CupertinoIcons.lock_open,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _unlock,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      isFullWidth: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                   TextButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await context.read<AuthProvider>().logout();
                      if (mounted) {
                        navigator.pushReplacementNamed('/login');
                      }
                    },
                    child: const Text('Switch User'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}