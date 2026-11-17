import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pattern_lock_widget.dart';

class LockTypeSelectionScreen extends StatefulWidget {
  const LockTypeSelectionScreen({super.key});

  @override
  State<LockTypeSelectionScreen> createState() => _LockTypeSelectionScreenState();
}

class _LockTypeSelectionScreenState extends State<LockTypeSelectionScreen> {
  String? _selectedType;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String _pattern = '';
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _saveLockType() async {
    if (_selectedType == null) {
      setState(() => _errorMessage = 'Please select a lock type.');
      return;
    }

    if (_selectedType == 'password') {
      if (_passwordController.text.trim().length < 4) {
        setState(() => _errorMessage = 'Password must be at least 4 characters.');
        return;
      }
      if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
        setState(() => _errorMessage = 'Passwords do not match.');
        return;
      }
    } else if (_selectedType == 'pin') {
      if (_pinController.text.trim().length < 4) {
        setState(() => _errorMessage = 'PIN must be at least 4 digits.');
        return;
      }
      if (_pinController.text.trim() != _confirmPinController.text.trim()) {
        setState(() => _errorMessage = 'PINs do not match.');
        return;
      }
    } else if (_selectedType == 'pattern') {
      if (_pattern.isEmpty) {
        setState(() => _errorMessage = 'Please draw a pattern lock.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final security = context.read<SecurityProvider>();
    bool success = false;

    if (_selectedType == 'password') {
      success = await security.changePassword(_passwordController.text.trim());
    } else if (_selectedType == 'pin') {
      success = await security.setPin(_pinController.text.trim());
    } else if (_selectedType == 'pattern') {
      success = await security.setPattern(_pattern);
    }

    if (success && mounted) {
      await security.setLockType(_selectedType!);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } else if (mounted) {
      setState(() {
        _errorMessage = security.errorMessage ?? 'Failed to save lock type.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Lock System'),
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(32),
              child: Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(CupertinoIcons.lock_shield, size: 48, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Select your preferred lock system',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can change this later in Settings',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _LockTypeCard(
                            icon: CupertinoIcons.lock,
                            title: 'Password',
                            isSelected: _selectedType == 'password',
                            onTap: () => setState(() => _selectedType = 'password'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LockTypeCard(
                            icon: CupertinoIcons.pin,
                            title: 'PIN',
                            isSelected: _selectedType == 'pin',
                            onTap: () => setState(() => _selectedType = 'pin'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LockTypeCard(
                            icon: Icons.grid_on,
                            title: 'Pattern',
                            isSelected: _selectedType == 'pattern',
                            onTap: () => setState(() => _selectedType = 'pattern'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if (_selectedType == 'password') ...[
                      Text('Set your password', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Min 4 characters',
                        prefixIcon: CupertinoIcons.lock,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 4) return 'Password must be at least 4 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Repeat password',
                        prefixIcon: CupertinoIcons.lock,
                        obscureText: _obscurePassword,
                        validator: (v) {
                          if (v != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ] else if (_selectedType == 'pin') ...[
                      Text('Set your PIN', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _pinController,
                        label: 'PIN',
                        hint: '4-6 digits',
                        prefixIcon: CupertinoIcons.lock,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'PIN is required';
                          if (v.length < 4) return 'PIN must be 4-6 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _confirmPinController,
                        label: 'Confirm PIN',
                        hint: 'Repeat PIN',
                        prefixIcon: CupertinoIcons.lock,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        validator: (v) {
                          if (v != _pinController.text) return 'PINs do not match';
                          return null;
                        },
                      ),
                    ] else if (_selectedType == 'pattern') ...[
                      Text('Draw your pattern lock', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Connect at least 4 dots',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: PatternLockWidget(
                          size: 220,
                          selectedColor: Theme.of(context).primaryColor,
                          onPatternComplete: (pattern) {
                            setState(() => _pattern = pattern);
                          },
                        ),
                      ),
                      if (_pattern.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Pattern captured',
                            style: TextStyle(color: Colors.green[600], fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],

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
                      label: _isLoading ? 'Saving...' : 'Continue',
                      icon: CupertinoIcons.check_mark,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _saveLockType,
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

class _LockTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LockTypeCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
