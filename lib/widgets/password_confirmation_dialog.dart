import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';

class PasswordConfirmationDialog extends StatefulWidget {
  final bool forceVerification;

  const PasswordConfirmationDialog({
    super.key,
    this.forceVerification = false,
  });

  @override
  State<PasswordConfirmationDialog> createState() => _PasswordConfirmationDialogState();

  static Future<bool> show(BuildContext context, {bool forceVerification = false}) async {
    final security = context.read<SecurityProvider>();

    if (!forceVerification && !security.isPasswordConfirmationRequired) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordConfirmationDialog(forceVerification: forceVerification),
    );

    if (result == true) {
      security.markPasswordConfirmed();
    }

    return result ?? false;
  }
}

class _PasswordConfirmationDialogState extends State<PasswordConfirmationDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final security = context.read<SecurityProvider>();
    final isValid = await security.authenticateWithPassword(_passwordController.text);

    if (!mounted) return;

    if (isValid) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = security.errorMessage ?? 'Incorrect password';
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Confirm Changes'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.forceVerification
                  ? 'Enter your password to proceed.'
                  : 'Enter your password to confirm this action.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              onSubmitted: (_) => _verifyPassword(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyPassword,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirm'),
        ),
      ],
    );
  }
}
