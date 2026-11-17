import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../mixins/route_aware_mixin.dart';
import '../../providers/sale_provider.dart';
import '../../models/sale.dart';
import '../../utils/money.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/data_table_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_icon.dart';
import '../../config/app_theme.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> with RouteAwareMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedPaymentMethod = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().ensureLoaded();
    });
  }

  @override
  void onScreenVisible() {
    context.read<SaleProvider>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final saleProvider = context.watch<SaleProvider>();
    final sales = _filterSales(saleProvider.todaySales);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Sales History'),
      drawer: const AppDrawer(currentRoute: '/sales'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _searchController,
                        label: 'Search sales',
                        hint: 'Invoice number or customer',
                        prefixIcon: CupertinoIcons.search,
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child:                       DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'Voided', child: Text('Voided')),
                        ],
                        onChanged: (value) => setState(() => _selectedStatus = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child:                       DropdownButtonFormField<String>(
                        initialValue: _selectedPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                          DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                          DropdownMenuItem(value: 'Credit', child: Text('Credit')),
                        ],
                        onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
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
                              Text(_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Start Date'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, isStart: false),
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
                              Text(_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'End Date'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _selectedStatus = 'All';
                          _selectedPaymentMethod = 'All';
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      icon: const AppIcon(icon: CupertinoIcons.clear, size: 18),
                      label: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${sales.length} sales found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                Text(
                   'Total: ${AppTheme.formatMoney(Money.fromDouble(sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount.asDouble)))}',
                  style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: saleProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             AppIcon(icon: CupertinoIcons.doc_text, size: 64, color: Colors.grey[400], fallbackText: '🧾'),
                            const SizedBox(height: 16),
                            Text('No sales found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                      )
                    : DataTableWidget(
                        columns: const [
                          DataColumn(label: Text('Invoice')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Customer')),
                          DataColumn(label: Text('Items')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Payment')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: sales
                            .map(
                              (sale) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      sale.invoiceNumber,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate)),
                                  ),
                                  DataCell(
                                    Expanded(
                                      child: Text(
                                        sale.customerName ?? 'Walk-in',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text('${sale.items.length} items')),
                                  DataCell(
                                    Text(
                                       AppTheme.formatMoney(sale.totalAmount),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataCell(Text(sale.paymentMethod)),
                                  DataCell(
                                    _buildStatusChip(sale.status),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const AppIcon(icon: CupertinoIcons.eye, size: 18, color: Colors.blue),
                                      tooltip: 'View Details',
                                      onPressed: () => _viewSaleDetails(context, sale),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushReplacementNamed(context, '/pos'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const AppIcon(icon: CupertinoIcons.cart, size: 20),
        label: const Text('New Sale'),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Completed':
        color = Colors.green;
        break;
      case 'Pending':
        color = Colors.orange;
        break;
      case 'Voided':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  List<Sale> _filterSales(List<Sale> sales) {
    var result = sales;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((sale) {
        return sale.invoiceNumber.toLowerCase().contains(query) ||
            (sale.customerName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    if (_selectedStatus != 'All') {
      result = result.where((sale) => sale.status == _selectedStatus).toList();
    }
    if (_selectedPaymentMethod != 'All') {
      result = result.where((sale) => sale.paymentMethod == _selectedPaymentMethod).toList();
    }
    if (_startDate != null) {
      result = result.where((sale) {
        final saleDate = DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        return saleDate.isAfter(start) || saleDate.isAtSameMomentAs(start);
      }).toList();
    }
    if (_endDate != null) {
      result = result.where((sale) {
        final saleDate = DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        return saleDate.isBefore(end) || saleDate.isAtSameMomentAs(end);
      }).toList();
    }
    return result;
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
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
    }
  }

  void _viewSaleDetails(BuildContext context, Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sale ${sale.invoiceNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Customer', sale.customerName ?? 'Walk-in'),
              _buildDetailRow('Date', DateFormat('dd MMM yyyy HH:mm').format(sale.saleDate)),
              _buildDetailRow('Payment Method', sale.paymentMethod),
              _buildDetailRow('Status', sale.status),
              const Divider(),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...sale.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${item.productName} x${item.quantity.toStringAsFixed(1)}')),
                      Text(AppTheme.formatMoney(item.totalAmount)),
                    ],
                  ),
                ),
              ),
              const Divider(),
              _buildDetailRow('Subtotal', AppTheme.formatMoney(sale.subtotal)),
              _buildDetailRow('Tax', AppTheme.formatMoney(sale.taxAmount)),
              if (sale.discountAmount.compareTo(Money.zero) > 0)
                _buildDetailRow('Discount', AppTheme.formatMoney(sale.discountAmount)),
              _buildDetailRow('Total', AppTheme.formatMoney(sale.totalAmount)),
              _buildDetailRow('Amount Paid', AppTheme.formatMoney(sale.amountPaid)),
              if (sale.balanceDue.compareTo(Money.zero) > 0)
                _buildDetailRow('Balance Due', AppTheme.formatMoney(sale.balanceDue), valueColor: Colors.orange),
              if (sale.notes != null && sale.notes!.isNotEmpty)
                _buildDetailRow('Notes', sale.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.black87, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
