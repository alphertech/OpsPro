import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../config/app_info.dart';
import '../../config/app_theme.dart';
import '../../services/sqlite_storage_service.dart';
import '../../services/app_startup_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final security = context.read<SecurityProvider>();
      final success = await security.loginWithUsername(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful! Welcome back.'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                security.errorMessage ?? 'Login failed. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showResetDialog() async {
    final security = context.read<SecurityProvider>();
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter your username first to reset your password.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    final challenge = await security.getPasswordResetChallenge(username);

    if (challenge == null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reset Password'),
            content: const Text('No account found for that username.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
      return;
    }

    if (challenge['hasQuestion'] != true) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reset Password'),
            content: const Text(
                'No security question is set for this account. Please contact the administrator.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
      return;
    }

    final questionText = challenge['question'] as String;
    final answerController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();

    if (!mounted) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Reset Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Security Question: $questionText'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: answerController,
                    decoration: const InputDecoration(
                        labelText: 'Your Answer', border: OutlineInputBorder()),
                    onSubmitted: (_) => FocusScope.of(ctx).nextFocus(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                        labelText: 'New Password', border: OutlineInputBorder()),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder()),
                    obscureText: true,
                    onSubmitted: (_) => Navigator.pop(ctx, {
                      'answer': answerController.text.trim(),
                      'password': newPasswordController.text.trim(),
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (newPasswordController.text != confirmController.text) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match.')),
                    );
                    return;
                  }
                  Navigator.pop(ctx, {
                    'answer': answerController.text.trim(),
                    'password': newPasswordController.text.trim(),
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      final reset = await security.resetPasswordViaSecurityQuestion(
        username,
        result['answer']!,
        result['password']!,
      );
      if (reset && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful. You can now log in.'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(security.errorMessage ?? 'Reset failed.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _createAccount() async {
    final security = context.read<SecurityProvider>();

    if (security.isFirstRun) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/security/setup');
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Create Account'),
          content: const Text(
            'New accounts are created by an administrator. Please log in as an '
            'admin and go to Settings → User Management to add users.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _showDeveloperResetDialog() async {
    final controller = TextEditingController();
    bool obscureKey = true;
    bool isLoading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> performReset() async {
            if (isLoading) return;
            setState(() {
              isLoading = true;
              errorMessage = null;
            });

            try {
              final sqlite = SqliteStorageService();
              await sqlite.deleteDatabaseFile();
              await AppStartupService().reset();

              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('System reset complete. Restarting...'),
                    backgroundColor: AppTheme.success,
                    duration: Duration(seconds: 3),
                  ),
                );
                Navigator.pop(ctx);
              }

              try {
                await Process.start(Platform.resolvedExecutable, [],
                    runInShell: true, mode: ProcessStartMode.detached);
                await Future.delayed(const Duration(seconds: 2));
              } catch (_) {}
              exit(0);
            } catch (e) {
              if (ctx.mounted) {
                setState(() {
                  isLoading = false;
                  errorMessage = 'Reset failed: $e';
                });
              }
            }
          }

          Future<void> verifyKey() async {
            final key = controller.text.trim();
            if (key != '*1*1*2*2') {
              setState(() {
                errorMessage = 'Invalid Developer Override Key.';
                controller.clear();
              });
              return;
            }
            await performReset();
          }

          return AlertDialog(
            title: const Text('Developer System Reset'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This will permanently delete all local data and restart the setup.'),
                const SizedBox(height: 12),
                const Text('Enter Developer Override Key to continue:'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  obscureText: obscureKey,
                  decoration: InputDecoration(
                    labelText: 'Developer Key',
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(obscureKey ? CupertinoIcons.eye_slash : CupertinoIcons.eye),
                      onPressed: () => setState(() => obscureKey = !obscureKey),
                    ),
                  ),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: isLoading ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isLoading ? null : verifyKey,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Reset System'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.eco,
                            size: 32, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppInfo.appName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppInfo.company} • Agricultural Management',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _usernameController,
                        label: 'Username',
                        prefixIcon: CupertinoIcons.person,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Username is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        prefixIcon: CupertinoIcons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? CupertinoIcons.eye_slash
                                : CupertinoIcons.eye,
                            size: 18,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        obscureText: _obscurePassword,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Password is required'
                            : null,
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          label: _isLoading ? 'Logging in...' : 'Login',
                          icon: CupertinoIcons.arrow_right,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _login,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          isFullWidth: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _showResetDialog,
                        child: const Text('Forgot Password?'),
                      ),
                      TextButton(
                        onPressed: _createAccount,
                        child: const Text('Create Account'),
                      ),
                      TextButton.icon(
                        onPressed: _showDeveloperResetDialog,
                        icon: const Icon(Icons.key, size: 16),
                        label: const Text('Developer Reset', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.check_mark_circled,
                                color: theme.colorScheme.primary, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '100% Offline System - No Internet Required',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Version ${AppInfo.appVersionDisplay}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
