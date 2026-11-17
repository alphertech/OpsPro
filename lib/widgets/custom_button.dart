import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final bool isFullWidth;
  final bool isCompact;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isCompact = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    final fgColor = foregroundColor ?? theme.colorScheme.onPrimary;

    final button = ElevatedButton.icon(
      onPressed: isLoading || onPressed == null ? null : onPressed,
      icon: isLoading
          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fgColor))
          : icon != null
              ? Icon(icon, size: isCompact ? 16 : 18)
              : const SizedBox.shrink(),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isCompact ? 13 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        minimumSize: isFullWidth ? null : Size(width ?? (isCompact ? 100 : 120), height ?? (isCompact ? 36 : 40)),
        maximumSize: isFullWidth ? const Size(double.infinity, 40) : null,
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: isCompact ? 8 : 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}