import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../mixins/route_aware_mixin.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/data_table_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/password_confirmation_dialog.dart';
import '../../config/app_theme.dart';
import 'customer_form_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> with RouteAwareMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOutstandingOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().ensureLoaded();
    });
  }

  @override
  void onScreenVisible() {
    context.read<CustomerProvider>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final customers = customerProvider.filteredCustomers(
      searchQuery: _searchQuery,
      withBalance: _showOutstandingOnly,
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Customers',
        actions: [
          IconButton(
            icon: AppIcon(icon: _showOutstandingOnly ? Icons.filter_alt : Icons.filter_alt, fallbackText: _showOutstandingOnly ? '🔽' : '🔼'),
            onPressed: () => setState(() => _showOutstandingOnly = !_showOutstandingOnly),
            tooltip: 'Filter by outstanding balance',
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/customers'),
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
                  flex: 2,
                  child: CustomTextField(
                    controller: _searchController,
                    label: 'Search customers',
                    hint: 'Name, phone, or email',
                    prefixIcon: CupertinoIcons.search,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  label: 'Add Customer',
                  icon: CupertinoIcons.add,
                  onPressed: () => _addCustomer(context),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  isCompact: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${customers.length} customers',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                Text(
                  'Outstanding: ${AppTheme.formatCurrency(customerProvider.customersWithOutstandingBalance.fold(0, (sum, c) => sum + c.currentBalance))}',
                  style: TextStyle(color: Colors.orange[700], fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: customerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No customers found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _addCustomer(context),
                              icon: const Icon(CupertinoIcons.add),
                              label: const Text('Add your first customer'),
                            ),
                          ],
                        ),
                      )
                    : DataTableWidget(
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Credit Limit')),
                          DataColumn(label: Text('Balance')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: customers
                            .map(
                              (customer) => DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                          child: Text(
                                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                customer.name,
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (customer.address != null && customer.address!.isNotEmpty)
                                                Text(
                                                  customer.address!,
                                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(customer.phone ?? '-'),
                                  ),
                                  DataCell(
                                    Text(customer.email ?? '-'),
                                  ),
                                  DataCell(
                                    Text(AppTheme.formatCurrency(customer.creditLimit)),
                                  ),
                                  DataCell(
                                    Text(
                                      AppTheme.formatCurrency(customer.currentBalance),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: customer.currentBalance > 0 ? Colors.orange : Colors.green,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: customer.isActive ? Colors.green[100] : Colors.red[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        customer.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: customer.isActive ? Colors.green[700] : Colors.red[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                          tooltip: 'Edit',
                                          onPressed: () => _editCustomer(context, customer),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.payment, size: 18, color: Colors.green),
                                          tooltip: 'Record Payment',
                                          onPressed: () => _recordPayment(context, customer),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          tooltip: 'Delete',
                                          onPressed: () => _deleteCustomer(context, customer),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
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
        onPressed: () => _addCustomer(context),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(CupertinoIcons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }

  void _addCustomer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerFormScreen()),
    );
  }

  void _editCustomer(BuildContext context, Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomerFormScreen(customer: customer)),
    );
  }

  void _recordPayment(BuildContext context, Customer customer) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Payment - ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance: ${AppTheme.formatCurrency(customer.currentBalance)}'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: amountController,
              label: 'Payment Amount (UGX)',
              hint: '0',
              keyboardType: TextInputType.number,
              prefixText: 'UGX ',
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Enter amount';
                final amount = double.tryParse(value.trim());
                if (amount == null || amount <= 0) return 'Enter valid amount';
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;
              final customerProvider = context.read<CustomerProvider>();
              final confirmed = await PasswordConfirmationDialog.show(context);
              if (!confirmed || !mounted) return;

              final newBalance = (customer.currentBalance - amount).clamp(0, double.infinity).toDouble();
              final success = await customerProvider.updateCustomerBalance(customer.id!, newBalance);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment recorded. New balance: ${AppTheme.formatCurrency(newBalance)}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  void _deleteCustomer(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete "${customer.name}"?\nThis action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final customerProvider = context.read<CustomerProvider>();
              final confirmed = await PasswordConfirmationDialog.show(context);
              if (!confirmed || !context.mounted) return;

              Navigator.pop(context);
              final success = await customerProvider.deleteCustomer(customer.id!);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Customer deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
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
