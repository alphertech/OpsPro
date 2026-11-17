import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../mixins/route_aware_mixin.dart';
import '../../providers/supplier_provider.dart';
import '../../models/supplier.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/data_table_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';
import 'supplier_form_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> with RouteAwareMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().ensureLoaded();
    });
  }

  @override
  void onScreenVisible() {
    context.read<SupplierProvider>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final suppliers = supplierProvider.suppliers.where((s) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(query) ||
          (s.contactPerson?.toLowerCase().contains(query) ?? false) ||
          (s.phone?.toLowerCase().contains(query) ?? false) ||
          (s.email?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Suppliers'),
      drawer: const AppDrawer(currentRoute: '/suppliers'),
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
                    label: 'Search suppliers',
                    hint: 'Name, contact, phone, or email',
                    prefixIcon: CupertinoIcons.search,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  label: 'Add Supplier',
                  icon: Icons.add_business,
                  onPressed: () => _addSupplier(context),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  isCompact: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${suppliers.length} suppliers',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: supplierProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : suppliers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No suppliers found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _addSupplier(context),
                              icon: const Icon(CupertinoIcons.add),
                              label: const Text('Add your first supplier'),
                            ),
                          ],
                        ),
                      )
                    : DataTableWidget(
                        columns: const [
                          DataColumn(label: Text('Supplier Name')),
                          DataColumn(label: Text('Contact Person')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Address')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: suppliers
                            .map(
                              (supplier) => DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                                          child: Text(
                                            supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.secondary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            supplier.name,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(supplier.contactPerson ?? '-')),
                                  DataCell(Text(supplier.phone ?? '-')),
                                  DataCell(Text(supplier.email ?? '-')),
                                  DataCell(
                                    Expanded(
                                      child: Text(
                                        supplier.address ?? '-',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                          tooltip: 'Edit',
                                          onPressed: () => _editSupplier(context, supplier),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          tooltip: 'Delete',
                                          onPressed: () => _deleteSupplier(context, supplier),
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
        onPressed: () => _addSupplier(context),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business),
        label: const Text('Add Supplier'),
      ),
    );
  }

  void _addSupplier(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupplierFormScreen()),
    );
  }

  void _editSupplier(BuildContext context, Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SupplierFormScreen(supplier: supplier)),
    );
  }

  void _deleteSupplier(BuildContext context, Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete "${supplier.name}"?\nThis action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final supplierProvider = context.read<SupplierProvider>();
              final confirmed = await PasswordConfirmationDialog.show(context);
              if (!confirmed || !context.mounted) return;

              Navigator.pop(context);
              final success = await supplierProvider.deleteSupplier(supplier.id!);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Supplier deleted successfully'),
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
}
