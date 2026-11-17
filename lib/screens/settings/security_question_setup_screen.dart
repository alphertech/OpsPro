import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../models/security.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_drawer.dart';

class SecurityQuestionSetupScreen extends StatefulWidget {
  const SecurityQuestionSetupScreen({super.key});

  @override
  State<SecurityQuestionSetupScreen> createState() => _SecurityQuestionSetupScreenState();
}

class _SecurityQuestionSetupScreenState extends State<SecurityQuestionSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _answerController = TextEditingController();
  SecurityQuestion? _selectedQuestion;
  bool _isLoading = false;
  String _errorMessage = '';
  List<SecurityQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final security = context.read<SecurityProvider>();
    final questions = await security.getRandomSecurityQuestions(4);
    if (mounted) {
      setState(() => _questions = questions);
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuestion == null) {
      setState(() => _errorMessage = 'Please select a security question.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final security = context.read<SecurityProvider>();
    final success = await security.setSecurityQuestion(
      _selectedQuestion!.id!,
      _answerController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      setState(() {
        _errorMessage = security.errorMessage ?? 'Failed to set security question.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Question'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.maybePop(context),
        ),
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
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/settings'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(CupertinoIcons.question_circle, size: 48, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Choose a security question',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will be used to verify your identity',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    if (_questions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('Loading questions...'),
                      )
                    else
                      ..._questions.map((q) {
                        final isSelected = _selectedQuestion?.id == q.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedQuestion = q),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? CupertinoIcons.check_mark_circled : CupertinoIcons.circle,
                                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[400],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    q.questionText,
                                    style: TextStyle(
                                      color: isSelected ? Theme.of(context).primaryColor : null,
                                      fontWeight: isSelected ? FontWeight.w600 : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _answerController,
                      label: 'Your Answer',
                      hint: 'Enter your answer',
                      prefixIcon: CupertinoIcons.pencil,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Answer is required';
                        return null;
                      },
                    ),

                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 24),
                    CustomButton(
                      label: _isLoading ? 'Saving...' : 'Save Question',
                      icon: CupertinoIcons.check_mark,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _saveQuestion,
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
