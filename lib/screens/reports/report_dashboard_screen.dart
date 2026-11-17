import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/sale_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/report_provider.dart';
import '../../models/sale.dart';
import '../../models/expense.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../config/app_theme.dart';

class ReportDashboardScreen extends StatefulWidget {
  const ReportDashboardScreen({super.key});

  @override
  State<ReportDashboardScreen> createState() => _ReportDashboardScreenState();
}

class _ReportDashboardScreenState extends State<ReportDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<Sale> _rangeSales = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      final saleProvider = context.read<SaleProvider>();
      final expenseProvider = context.read<ExpenseProvider>();
      final productProvider = context.read<ProductProvider>();
      final sales = await saleProvider.loadSalesByDateRange(_startDate, _endDate);
      await expenseProvider.loadExpenses();
      await productProvider.loadProducts();
      if (mounted) {
        setState(() {
          _rangeSales = sales;
        });
      }
    } catch (e) {
      // Ignore load errors; the UI will simply show empty sections.
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    final filteredSales = _rangeSales;
    final filteredExpenses = expenseProvider.filteredExpenses(startDate: _startDate, endDate: _endDate);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Reports'),
      drawer: const AppDrawer(currentRoute: '/reports'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, isStart: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text('${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _tabController.index == 0 ? '7d' : _tabController.index == 1 ? '30d' : '90d',
                  items: const [
                    DropdownMenuItem(value: '7d', child: Text('Last 7 Days')),
                    DropdownMenuItem(value: '30d', child: Text('Last 30 Days')),
                    DropdownMenuItem(value: '90d', child: Text('Last 90 Days')),
                  ],
                  onChanged: (value) {
                    if (value == '7d') {
                      setState(() {
                        _startDate = DateTime.now().subtract(const Duration(days: 7));
                        _endDate = DateTime.now();
                      });
                    } else if (value == '30d') {
                      setState(() {
                        _startDate = DateTime.now().subtract(const Duration(days: 30));
                        _endDate = DateTime.now();
                      });
                    } else if (value == '90d') {
                      setState(() {
                        _startDate = DateTime.now().subtract(const Duration(days: 90));
                        _endDate = DateTime.now();
                      });
                    }
                    _loadData();
                  },
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Sales'),
              Tab(text: 'Products'),
              Tab(text: 'Customers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(filteredSales, filteredExpenses, productProvider),
                _buildSalesTab(filteredSales),
                _buildProductsTab(filteredSales, productProvider),
                _buildCustomersTab(filteredSales, customerProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(List<Sale> sales, List<Expense> expenses, ProductProvider productProvider) {
    final totalSales = ReportProvider.calculateTotalSales(sales);
    final totalProfit = ReportProvider.calculateTotalProfit(sales);
    final totalExpenses = ReportProvider.calculateTotalExpenses(expenses);
    final netProfit = ReportProvider.calculateNetProfit(sales, expenses);
    final totalTransactions = ReportProvider.calculateTotalTransactions(sales);
    final avgSaleValue = ReportProvider.calculateAverageSaleValue(sales);
    final totalTax = ReportProvider.calculateTotalTaxCollected(sales);
    final outstandingBalance = ReportProvider.calculateTotalOutstandingBalance(sales);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _buildSummaryCard('Total Sales', AppTheme.formatCurrency(totalSales), Icons.trending_up, Theme.of(context).primaryColor),
              _buildSummaryCard('Net Profit', AppTheme.formatCurrency(netProfit), Icons.account_balance_wallet, netProfit >= 0 ? Colors.green : Colors.red),
              _buildSummaryCard('Expenses', AppTheme.formatCurrency(totalExpenses), Icons.money_off, Colors.red),
              _buildSummaryCard('Transactions', '$totalTransactions', Icons.receipt, Colors.purple),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/reports/weekly'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.date_range, color: Theme.of(context).primaryColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Weekly Reports', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text('Generate balance sheet, quotation, transaction sheet & trade statement', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/reports/z-report'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long, color: Colors.orange, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Z-Report / Close Day', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text('End-of-day cash reconciliation and daily closing', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financial Summary', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Total Revenue', AppTheme.formatCurrency(totalSales)),
                        _buildSummaryRow('Total Tax Collected', AppTheme.formatCurrency(totalTax)),
                        _buildSummaryRow('Total Discounts', AppTheme.formatCurrency(ReportProvider.calculateTotalDiscountGiven(sales))),
                        _buildSummaryRow('Total Profit', AppTheme.formatCurrency(totalProfit)),
                        _buildSummaryRow('Total Expenses', AppTheme.formatCurrency(totalExpenses)),
                        const Divider(),
                        _buildSummaryRow('Net Profit', AppTheme.formatCurrency(netProfit), isBold: true, valueColor: netProfit >= 0 ? Colors.green : Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Performance', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Avg. Sale Value', AppTheme.formatCurrency(avgSaleValue)),
                        _buildSummaryRow('Outstanding Balance', AppTheme.formatCurrency(outstandingBalance), valueColor: outstandingBalance > 0 ? Colors.orange : Colors.green),
                        _buildSummaryRow('Credit Customers', '${ReportProvider.calculateCreditCustomers(sales)}'),
                        _buildSummaryRow('Low Stock Items', '${productProvider.lowStockProducts.length}'),
                        _buildSummaryRow('Total Products', '${productProvider.products.length}'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab(List<Sale> sales) {
    final salesByDay = ReportProvider.getSalesByDay(sales);
    final salesByPayment = ReportProvider.getSalesByPaymentMethod(sales);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sales by Payment Method', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ...salesByPayment.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Container(
                          width: 120,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: entry.value / (salesByPayment.values.reduce((a, b) => a > b ? a : b)),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 100,
                          child: Text(
                            AppTheme.formatCurrency(entry.value),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Sales Breakdown', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ...salesByDay.entries.take(10).map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: TextStyle(color: Colors.grey[600])),
                        Text(AppTheme.formatCurrency(entry.value), style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(List<Sale> sales, ProductProvider productProvider) {
    final topProducts = ReportProvider.getTopSellingProducts(sales);
    final lowStock = productProvider.lowStockProducts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top Selling Products', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ...topProducts.take(10).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: index < 3 ? Theme.of(context).primaryColor : Colors.grey[300],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: index < 3 ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              product.key,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            AppTheme.formatCurrency(product.value),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Text('Low Stock Alert', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (lowStock.isEmpty)
                    Text('No low stock items', style: TextStyle(color: Colors.grey[600]))
                  else
                    ...lowStock.map(
                      (p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                             const Icon(Icons.warning, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${p.name}: ${p.currentStock.toStringAsFixed(1)} ${p.baseUnit} remaining',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersTab(List<Sale> sales, CustomerProvider customerProvider) {
    final customersWithBalance = customerProvider.customersWithOutstandingBalance;
    final totalOutstanding = customersWithBalance.fold<double>(0.0, (sum, c) => sum + c.currentBalance);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Credit Report', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Customers with Credit', '${customersWithBalance.length}'),
                  _buildSummaryRow('Total Outstanding', AppTheme.formatCurrency(totalOutstanding), valueColor: totalOutstanding > 0 ? Colors.orange : Colors.green),
                  _buildSummaryRow('Credit Customers Count', '${ReportProvider.calculateCreditCustomers(sales)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (customersWithBalance.isNotEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outstanding Balances', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...customersWithBalance.map(
                      (c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text(
                              AppTheme.formatCurrency(c.currentBalance),
                              style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _loadData();
    }
  }
}
