import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import '../../mixins/route_aware_mixin.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/report_provider.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/data_table_widget.dart';
import '../../widgets/app_drawer.dart';
import '../../config/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with RouteAwareMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = const [];
  List<Sale> _weeklySales = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() {
    Future.microtask(() {
      if (mounted) {
        context.read<ProductProvider>().ensureLoaded();
        context.read<SaleProvider>().loadTodaySales();
        context.read<CustomerProvider>().ensureLoaded();
        _loadWeeklySales();
      }
    });
  }

  Future<void> _loadWeeklySales() async {
    if (!mounted) return;
    try {
      final today = DateTime.now();
      final sixDaysAgo = today.subtract(const Duration(days: 6));
      final start = DateTime(sixDaysAgo.year, sixDaysAgo.month, sixDaysAgo.day);
      final end = DateTime(today.year, today.month, today.day, 23, 59, 59);
      final sales = await context.read<SaleProvider>().loadSalesByDateRange(start, end);
      if (mounted) {
        setState(() {
          _weeklySales = sales;
        });
      }
    } catch (e) {
      // Silently handle error
    }
  }

  @override
  void onScreenVisible() {
    _loadDashboardData();
    _loadWeeklySales();
  }

  void _onSearchChanged(String query) {
    final productProvider = context.read<ProductProvider>();
    if (query.isEmpty) {
      setState(() => _searchResults = const []);
    } else {
      setState(() {
        _searchResults = productProvider.filteredProducts(searchQuery: query);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Dashboard'),
      drawer: const AppDrawer(currentRoute: '/'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildWelcomeSection(context),
            const SizedBox(height: 16),
            _buildKPIGrid(context),
            const SizedBox(height: 16),
            _buildSearchResults(),
            const SizedBox(height: 16),
            _buildSalesTable(context),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildTopProducts(context)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildInventorySummary(context)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 2, child: _buildQuickActions(context)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildAlerts(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: Icon(Icons.search,
              color: theme.colorScheme.onSurfaceVariant, size: 18),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) return const SizedBox.shrink();
    if (_searchResults.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No products found for "${_searchController.text}"',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final product = _searchResults[index];
          return ListTile(
            dense: true,
            leading: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.inventory_2,
                  size: 14, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${product.currentStock.toStringAsFixed(1)} ${product.baseUnit} • ${AppTheme.formatMoney(product.sellingPrice)}',
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            trailing: TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/pos'),
              style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              child: const Text('Sell', style: TextStyle(fontSize: 11)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.timer,
                  color: Theme.of(context).colorScheme.primary, size: 14),
              const SizedBox(width: 4),
              Text(
                'Shift: Open',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKPIGrid(BuildContext context) {
    final saleProvider = context.watch<SaleProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final productProvider = context.watch<ProductProvider>();
    final totalSales = saleProvider.todaySales
        .fold<double>(0, (sum, sale) => sum + sale.totalAmount.asDouble);
    final totalCustomers = customerProvider.customers.length;
    final lowStockCount = productProvider.lowStockProducts.length;
    final profit = ReportProvider.calculateTotalProfit(saleProvider.todaySales);

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        DashboardCard(
          title: "Sales",
          value: AppTheme.formatCurrency(totalSales),
          icon: Icons.trending_up,
          color: Theme.of(context).colorScheme.primary,
        ),
        DashboardCard(
          title: 'Customers',
          value: '$totalCustomers',
          icon: Icons.people,
          color: Theme.of(context).colorScheme.secondary,
        ),
        DashboardCard(
          title: 'Low Stock',
          value: '$lowStockCount',
          icon: Icons.warning,
          color: Theme.of(context).colorScheme.tertiary,
          percentage: lowStockCount > 5 ? '!' : 'OK',
          percentageColor: Colors.white,
        ),
        DashboardCard(
          title: 'Profit',
          value: AppTheme.formatCurrency(profit),
          icon: Icons.account_balance_wallet,
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildSalesTable(BuildContext context) {
    final today = DateTime.now();
    final weeklySales = <double>[];
    final labels = <String>[];
    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      final dayTotal = _weeklySales
          .where((Sale s) =>
              s.saleDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
              s.saleDate.isBefore(end))
          .fold<double>(0, (double sum, Sale sale) => sum + sale.totalAmount.asDouble);
      weeklySales.add(dayTotal);
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      labels.add('${dayNames[day.weekday - 1]} ${day.day}');
    }
    final sales = weeklySales.map((v) => v.toInt()).toList();
    final total = sales.fold<int>(0, (sum, v) => sum + v);
    final average = sales.isNotEmpty ? total / sales.length : 0.0;
    final highest =
        sales.isNotEmpty ? sales.reduce((a, b) => a > b ? a : b) : 0;
    final lowest = sales.isNotEmpty ? sales.reduce((a, b) => a < b ? a : b) : 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sales Overview',
                    style: Theme.of(context).textTheme.titleSmall),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '7d',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DataTableWidget(
              columnSpacing: 12,
              columns: [
                const DataColumn(label: Text('Metric')),
                ...labels.map((l) => DataColumn(label: Text(l), numeric: true)),
              ],
              rows: [
                DataRow(
                  cells: [
                    const DataCell(Text('Sales',
                        style: TextStyle(fontWeight: FontWeight.w500))),
                    ...sales.map((v) => DataCell(Text('$v'))),
                  ],
                ),
                DataRow(
                  cells: [
                    const DataCell(Text('% of Total',
                        style: TextStyle(fontWeight: FontWeight.w500))),
                    ...sales.map((v) => DataCell(Text(total > 0
                        ? '${(v / total * 100).toStringAsFixed(1)}%'
                        : '0.0%'))),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            _buildStatRow('Total', AppTheme.formatCurrency(total.toDouble())),
            _buildStatRow('Average', AppTheme.formatCurrency(average)),
            _buildStatRow(
                'Highest', AppTheme.formatCurrency(highest.toDouble())),
            _buildStatRow('Lowest', AppTheme.formatCurrency(lowest.toDouble())),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInventorySummary(BuildContext context) {
    final products = context.watch<ProductProvider>().products;

    final itemsInStock =
        products.fold<double>(0, (sum, p) => sum + p.currentStock);
    final totalCost = products.fold<double>(
        0, (sum, p) => sum + (p.averageCost.asDouble * p.currentStock));
    final totalSelling = products.fold<double>(
        0, (sum, p) => sum + (p.sellingPrice.asDouble * p.currentStock));
    final expectedProfit = totalSelling - totalCost;
    final isProfit = expectedProfit >= 0;
    final profitColor = isProfit ? AppTheme.success : AppTheme.error;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inventory Summary',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            DataTableWidget(
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('Items in Stock')),
                DataColumn(label: Text('Total Cost'), numeric: true),
                DataColumn(label: Text('Total Selling'), numeric: true),
                DataColumn(label: Text('Expected Profit/Loss'), numeric: true),
              ],
              rows: [
                DataRow(
                  cells: [
                    DataCell(Text(itemsInStock.toStringAsFixed(1))),
                    DataCell(Text(AppTheme.formatCurrency(totalCost))),
                    DataCell(Text(AppTheme.formatCurrency(totalSelling))),
                    DataCell(
                      Text(
                        '${isProfit ? '+' : '-'}${AppTheme.formatCurrency(expectedProfit.abs())}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: profitColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(BuildContext context) {
    final products = context.watch<ProductProvider>().products.take(5).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Products', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            ...products.map(
              (product) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${product.currentStock.toStringAsFixed(1)} ${product.baseUnit}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppTheme.formatMoney(product.sellingPrice),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                    context,
                    'Sale',
                    Icons.add_shopping_cart,
                    Theme.of(context).colorScheme.primary,
                    () => Navigator.pushReplacementNamed(context, '/pos')),
                _buildActionButton(
                    context,
                    'Product',
                    Icons.inventory,
                    Theme.of(context).colorScheme.secondary,
                    () => Navigator.pushReplacementNamed(
                        context, '/products/add')),
                _buildActionButton(
                    context,
                    'Expense',
                    Icons.money_off,
                    AppTheme.error,
                    () => Navigator.pushReplacementNamed(
                        context, '/finances/expense')),
                _buildActionButton(context, 'Backup', Icons.backup,
                    AppTheme.warning, () => _showBackupDialog(context)),
                _buildActionButton(
                    context,
                    'Payment',
                    Icons.payment,
                    Theme.of(context).colorScheme.tertiary,
                    () => Navigator.pushReplacementNamed(
                        context, '/customers/payment')),
                _buildActionButton(
                    context,
                    'Report',
                    Icons.print,
                    AppTheme.info,
                    () => Navigator.pushReplacementNamed(context, '/reports')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerts(BuildContext context) {
    final lowStockProducts = context.watch<ProductProvider>().lowStockProducts;
    final overdueCustomers = context
        .watch<CustomerProvider>()
        .customersWithOutstandingBalance
        .length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active,
                    color: AppTheme.warning, size: 18),
                const SizedBox(width: 6),
                Text('Alerts', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${lowStockProducts.length + overdueCustomers}',
                    style: const TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (lowStockProducts.isNotEmpty)
              ...lowStockProducts.take(3).map(
                    (product) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.warning,
                              color: AppTheme.warning, size: 13),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${product.name}: ${product.currentStock} ${product.baseUnit}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            if (overdueCustomers > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: AppTheme.error, size: 13),
                    const SizedBox(width: 6),
                    Text('$overdueCustomers overdue payments',
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            if (lowStockProducts.isEmpty && overdueCustomers == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text('All clear!',
                      style: TextStyle(color: AppTheme.success, fontSize: 11)),
                ),
              ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/customers'),
              style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3)),
              child: const Text('View All', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Backup Database'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              'Feature Coming Soon',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Cloud backup and automatic backup management will be available in a future update.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }

  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0);
    return formatter.format(value);
  }
}
