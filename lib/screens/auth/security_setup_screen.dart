import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../models/security.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../config/app_theme.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _answerController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _errorMessage = '';
  int? _selectedQuestionId;
  List<SecurityQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final security = context.read<SecurityProvider>();
    final questions = await security.getSecurityQuestions();
    if (mounted) {
      setState(() {
        _questions = questions;
        if (questions.isNotEmpty) {
          _selectedQuestionId = questions.first.id;
        }
      });
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuestionId == null) {
      setState(() => _errorMessage = 'Please select a security question.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final security = context.read<SecurityProvider>();
    final success = await security.completeSecuritySetup(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      displayName: _usernameController.text.trim(),
      securityQuestionId: _selectedQuestionId,
      securityAnswer: _answerController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    } else if (mounted) {
      setState(() {
        _errorMessage = security.errorMessage ?? 'Setup failed. Please try again.';
        _isLoading = false;
      });
    }
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
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(CupertinoIcons.lock_shield, size: 40, color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Security Setup',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create your administrator account',
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
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Username is required';
                          if (v.trim().length < 3) return 'Username must be at least 3 characters';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Min 6 characters',
                        prefixIcon: CupertinoIcons.lock,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        prefixIcon: CupertinoIcons.lock_shield,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        validator: (v) {
                          if (v != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      if (_questions.isNotEmpty) ...[
                        Text(
                          'Security Question',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedQuestionId,
                              isExpanded: true,
                              items: _questions.map<DropdownMenuItem<int>>((q) {
                                return DropdownMenuItem<int>(
                                  value: q.id,
                                  child: Text(q.questionText),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedQuestionId = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          controller: _answerController,
                          label: 'Security Answer',
                          prefixIcon: CupertinoIcons.question_circle,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Security answer is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: AppTheme.error, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          label: _isLoading ? 'Setting up...' : 'Complete Setup',
                          icon: CupertinoIcons.check_mark,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _completeSetup,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          isFullWidth: true,
                        ),
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