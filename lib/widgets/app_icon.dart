import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  final IconData? icon;
  final String? fallbackText;
  final double size;
  final Color? color;

  const AppIcon({
    super.key,
    this.icon,
    this.fallbackText,
    this.size = 24,
    this.color,
  }) : assert(icon != null || fallbackText != null, 'Either icon or fallbackText must be provided');

  static const Map<String, IconData> _cupertinoFallbacks = {
    'home': CupertinoIcons.home,
    'dashboard': CupertinoIcons.graph_square,
    'pos': CupertinoIcons.cart,
    'products': CupertinoIcons.cube_box,
    'sales': CupertinoIcons.money_dollar_circle,
    'customers': CupertinoIcons.person_2,
    'suppliers': Icons.local_shipping,
    'finances': CupertinoIcons.money_dollar,
    'reports': CupertinoIcons.chart_bar_square,
    'settings': CupertinoIcons.settings,
    'users': CupertinoIcons.person,
    'backup': CupertinoIcons.cloud_download,
    'logout': CupertinoIcons.escape,
    'add': CupertinoIcons.add,
    'edit': CupertinoIcons.pencil,
    'delete': CupertinoIcons.delete,
    'search': CupertinoIcons.search,
    'filter': CupertinoIcons.arrow_up_arrow_down,
    'calendar': CupertinoIcons.calendar,
    'clear': CupertinoIcons.clear_thick,
    'menu': CupertinoIcons.bars,
    'back': CupertinoIcons.chevron_back,
    'close': CupertinoIcons.clear_circled,
    'check': CupertinoIcons.check_mark_circled,
    'warning': CupertinoIcons.exclamationmark_triangle,
    'error': CupertinoIcons.xmark_circle,
    'success': CupertinoIcons.check_mark_circled,
    'person': CupertinoIcons.person,
    'inventory': CupertinoIcons.list_bullet,
    'money': CupertinoIcons.money_dollar,
    'trending_up': CupertinoIcons.arrow_up,
    'receipt': CupertinoIcons.doc_text,
    'payment': CupertinoIcons.creditcard,
    'print': CupertinoIcons.printer,
    'location': CupertinoIcons.location,
    'lock': CupertinoIcons.lock,
    'unlock': CupertinoIcons.lock_open,
    'refresh': CupertinoIcons.refresh,
  };

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).iconTheme.color ?? const Color(0xFF2E7D32);
    
    if (icon != null) {
      return Icon(icon, size: size, color: iconColor);
    }
    
    if (fallbackText != null) {
      final lowerKey = fallbackText!.toLowerCase();
      final cupertinoIcon = _cupertinoFallbacks[lowerKey];
      if (cupertinoIcon != null) {
        return Icon(cupertinoIcon, size: size, color: iconColor);
      }
      return Text(
        fallbackText!,
        style: TextStyle(fontSize: size * 0.8, color: iconColor),
      );
    }
    
    return const SizedBox.shrink();
  }
}
