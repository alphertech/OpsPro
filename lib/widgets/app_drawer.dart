import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  final String? currentRoute;

  const AppDrawer({super.key, this.currentRoute});

  static const List<(IconData, String, String, String)> _mainItems = [
    (CupertinoIcons.home, 'Dashboard', '/', 'dashboard_view'),
    (CupertinoIcons.cart, 'Point of Sale', '/pos', 'pos_access'),
    (CupertinoIcons.cube_box, 'Products', '/products', 'products_view'),
    (CupertinoIcons.doc_text, 'Sales', '/sales', 'sales_view'),
    (CupertinoIcons.person_2, 'Customers', '/customers', 'customers_view'),
    (Icons.local_shipping, 'Suppliers', '/suppliers', 'suppliers_view'),
  ];

  static const List<(IconData, String, String, String)> _financeItems = [
    (CupertinoIcons.money_dollar, 'Finances', '/finances', 'finances_view'),
    (Icons.account_balance, 'Accounting', '/accounting', 'accounting_view'),
    (Icons.shopping_cart, 'Purchase Orders', '/purchasing/orders', 'purchasing_view'),
  ];

  static const List<(IconData, String, String, String)> _hrItems = [
    (Icons.people, 'Employees', '/hr/employees', 'hr_view'),
    (Icons.event_busy, 'Leave Management', '/hr/leave', 'hr_view'),
    (Icons.schedule, 'Shift Schedule', '/hr/shifts', 'hr_view'),
    (Icons.receipt_long, 'Reimbursements', '/hr/reimbursements', 'hr_view'),
  ];

  static const List<(IconData, String, String, String)> _inventoryItems = [
    (Icons.warehouse, 'Warehouses', '/inventory/warehouses', 'inventory_view'),
    (Icons.swap_horiz, 'Stock Transfers', '/inventory/stock-transfers', 'inventory_view'),
  ];

  static const List<(IconData, String, String, String)> _projectItems = [
    (Icons.folder, 'Projects', '/projects', 'projects_view'),
  ];

  static const List<(IconData, String, String, String)> _commItems = [
    (Icons.email, 'Email Queue', '/communication/email-queue', 'communication_view'),
    (Icons.note, 'Memo Board', '/communication/memo-board', 'communication_view'),
  ];

  static const List<(IconData, String, String, String)> _reportItems = [
    (CupertinoIcons.chart_bar_square, 'Reports', '/reports', 'reports_view'),
  ];

  static const List<(IconData, String, String, String)> _settingsItems = [
    (CupertinoIcons.settings, 'Settings', '/settings', 'system_settings'),
    (Icons.currency_exchange, 'Currency & Tax', '/settings/currency-tax', 'system_settings'),
    (Icons.monitor_heart, 'System Health', '/settings/system-health', 'system_settings'),
    (Icons.support_agent, 'Support & About', '/support', 'system_settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final auth = context.watch<SecurityProvider>();
    final userName = auth.currentUser?.displayName ?? 'User';
    final userRole = auth.currentUser?.role ?? 'Cashier';
    final authProvider = context.watch<AuthProvider>();

    return Drawer(
      width: 260,
      child: Column(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(CupertinoIcons.person_fill, size: 24, color: primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  userName,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  userRole,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                ..._buildSection(context, _mainItems, null, authProvider),
                const Divider(height: 8, indent: 16, endIndent: 16),
                ..._buildSection(context, _financeItems, 'Finance', authProvider),
                const Divider(height: 8, indent: 16, endIndent: 16),
                ..._buildSection(context, _hrItems, 'Human Resources', authProvider),
                const Divider(height: 8, indent: 16, endIndent: 16),
                ..._buildSection(context, _inventoryItems, 'Inventory', authProvider),
                const Divider(height: 8, indent: 16, endIndent: 16),
                ..._buildSection(context, _projectItems, 'Projects', authProvider),
                const Divider(height: 8, indent: 16, endIndent: 16),
                ..._buildSection(context, _commItems, 'Communication', authProvider),
                const Divider(height: 8, indent: 16, endIndent: 16),
                ..._buildSection(context, _reportItems, null, authProvider),
                const Divider(height: 8, indent: 16, endIndent: 16),
                ..._buildSection(context, _settingsItems, 'System', authProvider),
                const Divider(height: 8, indent: 16, endIndent: 16),
                  ListTile(
                  leading: const Icon(CupertinoIcons.escape, size: 20),
                  title: const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  onTap: () {
                    // Capture the provider while the drawer context is still
                    // valid. The drawer is popped before the confirm handler
                    // runs, so using context.read/navigate later would operate
                    // on a deactivated context and silently fail.
                    final security = context.read<SecurityProvider>();
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              await security.logout();
                              if (ctx.mounted) {
                                // Clears the whole stack (including the dialog
                                // route) and shows the login screen.
                                Navigator.of(ctx).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              }
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSection(BuildContext context, List<(IconData, String, String, String)> items, String? title, AuthProvider authProvider) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final widgets = <Widget>[];

    if (title != null) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    final filteredItems = items.where((item) => authProvider.hasPermission(item.$4)).toList();

    for (final item in filteredItems) {
      final isSelected = currentRoute == item.$3;
      widgets.add(
        ListTile(
          dense: true,
          leading: Icon(
            item.$1,
            size: 18,
            color: isSelected ? primaryColor : Theme.of(context).iconTheme.color,
          ),
          title: Text(
            item.$2,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? primaryColor : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          selected: isSelected,
          onTap: () {
            Navigator.pop(context);
            if (currentRoute != item.$3) {
              try {
                Navigator.pushReplacementNamed(context, item.$3);
              } catch (e) {
                debugPrint('Navigation failed: $e');
              }
            }
          },
        ),
      );
    }

    return widgets;
  }
}