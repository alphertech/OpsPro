import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pattern_lock_widget.dart';
import '../../widgets/app_drawer.dart';

class PatternSetupScreen extends StatefulWidget {
  const PatternSetupScreen({super.key});

  @override
  State<PatternSetupScreen> createState() => _PatternSetupScreenState();
}

class _PatternSetupScreenState extends State<PatternSetupScreen> {
  String _pattern = '';
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _savePattern() async {
    if (_pattern.isEmpty) {
      setState(() => _errorMessage = 'Please draw a pattern lock.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final security = context.read<SecurityProvider>();
    final success = await security.setPattern(_pattern);

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      setState(() {
        _errorMessage = security.errorMessage ?? 'Failed to set pattern.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Pattern Lock'),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Icon(Icons.grid_on, size: 48, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Draw a pattern lock',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect at least 4 dots',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

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
                    label: _isLoading ? 'Saving...' : 'Save Pattern',
                    icon: CupertinoIcons.check_mark,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _savePattern,
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
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
