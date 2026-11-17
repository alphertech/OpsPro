import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import 'app_icon.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLockButton;
  final bool showMenuButton;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showLockButton = true,
    this.showMenuButton = true,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return AppBar(
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.maybePop(context),
            )
          : showMenuButton
              ? IconButton(
                  icon: const AppIcon(icon: CupertinoIcons.bars, size: 20),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                )
              : null,
      title: Row(
        children: [
          const AppIcon(icon: CupertinoIcons.graph_square, size: 20, color: Colors.white),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      backgroundColor: primaryColor,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      actions: [
        if (showLockButton)
          IconButton(
            icon: const AppIcon(icon: CupertinoIcons.lock, size: 18),
            tooltip: 'Lock Session',
            onPressed: () {
              context.read<SecurityProvider>().lockSession();
            },
          ),
        if (actions != null) ...actions!,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const AppIcon(icon: CupertinoIcons.person, size: 16, fallbackText: '👤'),
              const SizedBox(width: 6),
              Text(
                context.watch<SecurityProvider>().currentUser?.displayName ?? 'User',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(52);
}