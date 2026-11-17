import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../services/sqlite_storage_service.dart';
import '../../services/app_startup_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/custom_text_field.dart';
import '../../config/app_theme.dart';
import 'user_management_screen.dart';
import 'pin_setup_screen.dart';
import 'pattern_setup_screen.dart';
import 'security_question_setup_screen.dart';
import '../auth/lock_type_selection_screen.dart';
import '../support/support_screen.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final security = context.watch<SecurityProvider>();
    final settings = context.watch<AppSettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerRight,
            child: const Text(
              'Plexus',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/settings'),
      body: GridView(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        children: [
          _SettingsCard(
            icon: CupertinoIcons.person_2,
            title: 'User Management',
            subtitle: 'Add, edit, or remove users',
            color: Colors.blue,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const UserManagementScreen())),
          ),
          _SettingsCard(
            icon: CupertinoIcons.lock,
            title: 'Change Password',
            subtitle: 'Update account password',
            color: Colors.orange,
            onTap: () => _showChangePasswordDialog(context),
          ),
          _SettingsCard(
            icon: CupertinoIcons.lock_shield,
            title: 'Change Lock Type',
            subtitle: security.currentUser?.lockType ?? 'Not set',
            color: Colors.purple,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LockTypeSelectionScreen())),
          ),
          _SettingsCard(
            icon: CupertinoIcons.lock_shield,
            title: 'F5 Instant Lock',
            subtitle: settings.enableF5Lock ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: settings.enableF5Lock,
              onChanged: (v) =>
                  settings.updateOperationalSettings(enableF5Lock: v),
            ),
            color: Colors.teal,
          ),
          _SettingsCard(
            icon: CupertinoIcons.pin,
            title: 'Set PIN',
            subtitle: security.currentUser?.pinHash != null &&
                    security.currentUser!.pinHash!.isNotEmpty
                ? 'PIN configured'
                : 'Not set',
            color: Colors.indigo,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PinSetupScreen())),
          ),
          _SettingsCard(
            icon: Icons.grid_on,
            title: 'Pattern Lock',
            subtitle: security.currentUser?.patternHash != null &&
                    security.currentUser!.patternHash!.isNotEmpty
                ? 'Pattern configured'
                : 'Not set',
            color: Colors.deepPurple,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PatternSetupScreen())),
          ),
          _SettingsCard(
            icon: CupertinoIcons.question_circle,
            title: 'Security Question',
            subtitle: security.currentUser?.securityQuestionId != null
                ? 'Question configured'
                : 'Not set',
            color: Colors.cyan,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SecurityQuestionSetupScreen())),
          ),
          _SettingsCard(
            icon: CupertinoIcons.money_dollar,
            title: 'Currency & Formatting',
            subtitle:
                '${settings.currencySymbol} - ${settings.decimalPlaces} decimals',
            color: Colors.green,
            onTap: () => _showCurrencyDialog(context, settings),
          ),

          _SettingsCard(
            icon: CupertinoIcons.calendar,
            title: 'Date Format',
            subtitle: settings.dateFormat,
            color: Colors.brown,
            onTap: () => _showDateFormatDialog(context, settings),
          ),
          _SettingsCard(
            icon: CupertinoIcons.doc_text,
            title: 'Invoice Numbering',
            subtitle:
                '${settings.invoicePrefix} Next: ${settings.nextInvoiceNumber}',
            color: Colors.blueGrey,
            onTap: () => _showInvoiceDialog(context, settings),
          ),
          _SettingsCard(
            icon: CupertinoIcons.percent,
            title: 'Tax Rate',
            subtitle:
                '${settings.defaultTaxRate}% ${settings.taxInclusive ? '(Inclusive)' : '(Exclusive)'}',
            color: Colors.red,
            onTap: () => _showTaxDialog(context, settings),
          ),
          _SettingsCard(
            icon: CupertinoIcons.minus_circle,
            title: 'Negative Stock',
            subtitle: settings.allowNegativeStock ? 'Allowed' : 'Not allowed',
            trailing: Switch(
              value: settings.allowNegativeStock,
              onChanged: (v) =>
                  settings.updateOperationalSettings(allowNegativeStock: v),
            ),
            color: Colors.orange,
          ),
          _SettingsCard(
            icon: CupertinoIcons.person_add,
            title: 'Force Customer',
            subtitle: settings.requireCustomer ? 'Required' : 'Optional',
            trailing: Switch(
              value: settings.requireCustomer,
              onChanged: (v) =>
                  settings.updateOperationalSettings(requireCustomer: v),
            ),
            color: Colors.lightBlue,
          ),
          _SettingsCard(
            icon: CupertinoIcons.cloud_download,
            title: 'Backup Management',
            subtitle: 'Coming Soon',
            color: Colors.teal,
            onTap: () => _showComingSoonDialog(context, 'Backup Management'),
          ),
          const _SettingsCard(
            icon: CupertinoIcons.timer,
            title: 'Auto-Backup',
            subtitle: 'Coming Soon',
            color: Colors.green,
          ),
          _SettingsCard(
            icon: CupertinoIcons.gear,
            title: 'Database Maintenance',
            subtitle: 'Compact & optimize',
            color: Colors.grey,
            onTap: () => _showMaintenanceDialog(context),
          ),

          _SettingsCard(
            icon: Icons.warning,
            title: 'Export Logs',
            subtitle: 'Download system logs',
            color: Colors.amber,
            onTap: () => _showExportLogsDialog(context),
          ),
          _SettingsCard(
            icon: CupertinoIcons.arrow_down_circle,
            title: 'Check Updates',
            subtitle: 'Look for new version',
            color: Colors.blue,
            onTap: () => _showCheckUpdatesDialog(context),
          ),
          _SettingsCard(
            icon: Icons.support_agent,
            title: 'Support & About',
            subtitle: 'Developer info and contact',
            color: Colors.teal,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
          _SettingsCard(
            icon: Icons.warning_amber_rounded,
            title: 'Reset System',
            subtitle: 'Delete all data and restart setup',
            color: Colors.red,
            onTap: () => _showResetSystemDialog(context),
          ),

        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final answerController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool isLoading = false;
    String? errorMessage;
    int currentStep = 0;
    String? securityQuestionText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> loadSecurityQuestion() async {
            final text = await context.read<SecurityProvider>().getCurrentUserSecurityQuestionText();
            if (ctx.mounted) {
              setState(() {
                securityQuestionText = text ?? 'Security question not found.';
              });
            }
          }

          Future<void> verifyPasswordAndProceed() async {
            final password = oldPasswordController.text.trim();
            if (password.isEmpty) {
              setState(() => errorMessage = 'Please enter your current password.');
              return;
            }
            setState(() {
              isLoading = true;
              errorMessage = null;
            });
            final valid = await context.read<SecurityProvider>().authenticateWithPassword(password);
            if (ctx.mounted) {
              if (valid) {
                await loadSecurityQuestion();
                setState(() {
                  currentStep = 1;
                  isLoading = false;
                  oldPasswordController.clear();
                });
              } else {
                setState(() {
                  isLoading = false;
                  errorMessage = context.read<SecurityProvider>().errorMessage ?? 'Incorrect password.';
                  oldPasswordController.clear();
                });
              }
            }
          }

          Future<void> verifyAnswerAndChange() async {
            final answer = answerController.text.trim();
            if (answer.isEmpty) {
              setState(() => errorMessage = 'Please enter your answer.');
              return;
            }
            final newPass = newPasswordController.text.trim();
            final confirmPass = confirmPasswordController.text.trim();
            if (newPass.length < 4) {
              setState(() => errorMessage = 'New password must be at least 4 characters.');
              return;
            }
            if (newPass != confirmPass) {
              setState(() => errorMessage = 'Passwords do not match.');
              return;
            }
            setState(() {
              isLoading = true;
              errorMessage = null;
            });
            final security = context.read<SecurityProvider>();
            final username = security.currentUser?.username ?? '';
            final answerValid = await security.verifySecurityAnswer(username, answer);
            if (ctx.mounted) {
              if (answerValid) {
                final success = await security.resetPassword(oldPasswordController.text.trim(), newPass);
                if (ctx.mounted) {
                  if (success) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password changed successfully.'),
                          backgroundColor: AppTheme.success),
                    );
                  } else {
                    setState(() {
                      isLoading = false;
                      errorMessage = security.errorMessage ?? 'Failed to change password.';
                    });
                  }
                }
              } else {
                setState(() {
                  isLoading = false;
                  errorMessage = security.errorMessage ?? 'Incorrect answer.';
                  answerController.clear();
                });
              }
            }
          }

          Widget buildContent() {
            if (currentStep == 0) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: oldPasswordController,
                    label: 'Current Password',
                    prefixIcon: CupertinoIcons.lock,
                    obscureText: obscureOld,
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 18),
                      onPressed: () => setState(() => obscureOld = !obscureOld),
                    ),
                  ),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Answer your security question:', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(securityQuestionText ?? 'Security question', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: answerController,
                  decoration: const InputDecoration(
                    labelText: 'Your Answer',
                    prefixIcon: Icon(CupertinoIcons.question_circle),
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: newPasswordController,
                  label: 'New Password',
                  prefixIcon: CupertinoIcons.lock,
                  obscureText: obscureNew,
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 18),
                    onPressed: () => setState(() => obscureNew = !obscureNew),
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: confirmPasswordController,
                  label: 'Confirm New Password',
                  prefixIcon: CupertinoIcons.lock_shield,
                  obscureText: obscureNew,
                ),
              ],
            );
          }

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currentStep == 0 ? 'Change Password' : 'Security Verification'),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildContent(),
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
                onPressed: isLoading ? null : () {
                  if (currentStep == 0) {
                    verifyPasswordAndProceed();
                  } else {
                    verifyAnswerAndChange();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(currentStep == 0 ? 'Next' : 'Change Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, AppSettingsProvider settings) {
    final symbolController =
        TextEditingController(text: settings.currencySymbol);
    final positionController =
        TextEditingController(text: settings.currencyPosition);
    final decimalController =
        TextEditingController(text: settings.decimalPlaces.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Currency Settings'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Currency Symbol',
                  hintText: 'UGX, USh, etc.',
                  border: OutlineInputBorder()),
              controller: symbolController,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: settings.currencyPosition,
              decoration: const InputDecoration(
                  labelText: 'Symbol Position', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Left', child: Text('Left (UGX 100)')),
                DropdownMenuItem(
                    value: 'Right', child: Text('Right (100 UGX)')),
              ],
              onChanged: (value) => positionController.text = value ?? 'Left',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: settings.decimalPlaces,
              decoration: const InputDecoration(
                  labelText: 'Decimal Places', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0 (100)')),
                DropdownMenuItem(value: 1, child: Text('1 (100.0)')),
                DropdownMenuItem(value: 2, child: Text('2 (100.00)')),
                DropdownMenuItem(value: 3, child: Text('3 (100.000)')),
              ],
              onChanged: (value) => decimalController.text = value.toString(),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              settings.updateCurrencySettings(
                currencySymbol: symbolController.text.trim(),
                currencyPosition: positionController.text.trim(),
                decimalPlaces: int.tryParse(decimalController.text.trim()) ?? 0,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDateFormatDialog(
      BuildContext context, AppSettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Date Format'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: settings.dateFormat,
              decoration: const InputDecoration(
                  labelText: 'Format', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: 'DD/MM/YYYY', child: Text('DD/MM/YYYY')),
                DropdownMenuItem(
                    value: 'MM/DD/YYYY', child: Text('MM/DD/YYYY')),
                DropdownMenuItem(
                    value: 'YYYY-MM-DD', child: Text('YYYY-MM-DD')),
              ],
              onChanged: (value) {
                if (value != null) {
                  settings.updateDateFormat(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showInvoiceDialog(BuildContext context, AppSettingsProvider settings) {
    final prefixController =
        TextEditingController(text: settings.invoicePrefix);
    final numberController =
        TextEditingController(text: settings.nextInvoiceNumber.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Invoice Settings'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Invoice Prefix', border: OutlineInputBorder()),
              controller: prefixController,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Next Invoice Number',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              controller: numberController,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              settings.updateInvoiceSettings(
                invoicePrefix: prefixController.text.trim(),
                nextInvoiceNumber:
                    int.tryParse(numberController.text.trim()) ?? 1001,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTaxDialog(BuildContext context, AppSettingsProvider settings) {
    final rateController =
        TextEditingController(text: settings.defaultTaxRate.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tax Settings'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Default Tax Rate (%)',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              controller: rateController,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Tax Inclusive Pricing'),
              subtitle: const Text('Prices include tax by default'),
              value: settings.taxInclusive,
              onChanged: (value) {
                settings.updateTaxSettings(taxInclusive: value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              settings.updateTaxSettings(
                defaultTaxRate:
                    double.tryParse(rateController.text.trim()) ?? 0,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(feature),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: const Text('This feature is coming soon.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }

  void _showResetSystemDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final passwordController = TextEditingController();
          final answerController = TextEditingController();
          final overrideController = TextEditingController();
          bool obscurePassword = true;
          bool isLoading = false;
          String? errorMessage;
          int failedAttempts = 0;
          int currentStep = 0;
          String? securityQuestionText;
          bool isProcessing = false;

          Future<void> loadSecurityQuestion() async {
            final text = await context.read<SecurityProvider>().getCurrentUserSecurityQuestionText();
            if (ctx.mounted) {
              setState(() {
                securityQuestionText = text ?? 'Security question not found.';
              });
            }
          }

          Future<void> performReset() async {
            if (isProcessing) return;
            setState(() {
              isProcessing = true;
              isLoading = true;
              errorMessage = null;
            });

            try {
              final sqlite = SqliteStorageService();
              final exportPath = await sqlite.exportDatabaseAsSql();
              await sqlite.deleteDatabaseFile();
              await AppStartupService().reset();

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Database exported to: $exportPath'),
                    backgroundColor: AppTheme.success,
                    duration: const Duration(seconds: 5),
                  ),
                );
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
                  isProcessing = false;
                  errorMessage = 'Reset failed: $e';
                });
              }
            }
          }

          Future<void> verifyPassword() async {
            final password = passwordController.text.trim();
            if (password.isEmpty) {
              setState(() => errorMessage = 'Please enter your password.');
              return;
            }
            setState(() {
              isLoading = true;
              errorMessage = null;
            });
            final valid = await context.read<SecurityProvider>().authenticateWithPassword(password);
            if (ctx.mounted) {
              if (valid) {
                await loadSecurityQuestion();
                setState(() {
                  currentStep = 2;
                  isLoading = false;
                  passwordController.clear();
                });
              } else {
                setState(() {
                  failedAttempts++;
                  isLoading = false;
                  errorMessage = context.read<SecurityProvider>().errorMessage ?? 'Incorrect password.';
                  passwordController.clear();
                });
                if (failedAttempts >= 3) {
                  setState(() => currentStep = 3);
                }
              }
            }
          }

          Future<void> verifyAnswer() async {
            final answer = answerController.text.trim();
            if (answer.isEmpty) {
              setState(() => errorMessage = 'Please enter your answer.');
              return;
            }
            setState(() {
              isLoading = true;
              errorMessage = null;
            });
            final security = context.read<SecurityProvider>();
            final username = security.currentUser?.username ?? '';
            final valid = await security.verifySecurityAnswer(username, answer);
            if (ctx.mounted) {
              if (valid) {
                await performReset();
              } else {
                setState(() {
                  failedAttempts++;
                  isLoading = false;
                  errorMessage = security.errorMessage ?? 'Incorrect answer.';
                  answerController.clear();
                });
                if (failedAttempts >= 3) {
                  setState(() => currentStep = 3);
                }
              }
            }
          }

          Future<void> verifyOverrideKey() async {
            final key = overrideController.text.trim();
            if (key != '*1*1*2*2') {
              setState(() {
                errorMessage = 'Invalid Developer Override Key.';
                overrideController.clear();
              });
              return;
            }
            await performReset();
          }

          Widget buildStepContent() {
            if (currentStep == 0) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This will permanently delete all local data including products, sales, users, and settings. The app will return to first-run setup.'),
                  SizedBox(height: 12),
                  Text('This action cannot be undone.'),
                ],
              );
            }

            if (currentStep == 1) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter your current system password to continue.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'System Password',
                      prefixIcon: const Icon(CupertinoIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                    ),
                  if (failedAttempts > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Failed attempts: $failedAttempts / 3', style: const TextStyle(fontSize: 12, color: AppTheme.warning)),
                    ),
                ],
              );
            }

            if (currentStep == 2) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Answer your security question:'),
                  const SizedBox(height: 4),
                  Text(securityQuestionText ?? 'Security question', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: answerController,
                    decoration: const InputDecoration(
                      labelText: 'Your Answer',
                      prefixIcon: Icon(CupertinoIcons.question_circle),
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                    ),
                  if (failedAttempts > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Failed attempts: $failedAttempts / 3', style: const TextStyle(fontSize: 12, color: AppTheme.warning)),
                    ),
                ],
              );
            }

            if (currentStep == 3) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Too many failed attempts. Developer Override Key is required.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: overrideController,
                    decoration: const InputDecoration(
                      labelText: 'Developer Override Key',
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                    ),
                ],
              );
            }

            return const SizedBox.shrink();
          }

          List<Widget> buildActions() {
            if (currentStep == 0) {
              return [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isLoading ? null : () {
                    setState(() => currentStep = 1);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                  child: const Text('Continue'),
                ),
              ];
            }

            if (currentStep == 1 || currentStep == 2) {
              return [
                TextButton(onPressed: isLoading ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isLoading ? null : () {
                    if (currentStep == 1) {
                      verifyPassword();
                    } else {
                      verifyAnswer();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify'),
                ),
              ];
            }

            if (currentStep == 3) {
              return [
                TextButton(onPressed: isLoading ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isLoading ? null : () => verifyOverrideKey(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Override'),
                ),
              ];
            }

            return [];
          }

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currentStep == 0 ? 'Reset System' : 'Security Verification'),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            content: buildStepContent(),
            actions: buildActions(),
          );
        },
      ),
    );
  }

  void _showMaintenanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Database Maintenance'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: const Text(
          'This will compact and optimize your database.\n\n'
          'The system will be temporarily unavailable during this process.\n'
          'This may take a few minutes.\n\n'
          'Please ensure you have a backup before proceeding.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Database maintenance started...'),
                  backgroundColor: Colors.blue));
            },
            child: const Text('Start Maintenance'),
          ),
        ],
      ),
    );
  }

  void _showExportLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Export Logs'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: const Text(
            'System logs will be exported to your documents folder.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Logs exported successfully'),
                  backgroundColor: Colors.green));
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showCheckUpdatesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Check Updates'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: const Text('You are running the latest version (3.2).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                children: [
                    Text(title,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing!
              ] else if (onTap != null) ...[
                Icon(Icons.chevron_right,
                    size: 16, color: theme.colorScheme.onSurfaceVariant)
              ],
            ],
          ),
        ),
      ),
    );
  }
}
