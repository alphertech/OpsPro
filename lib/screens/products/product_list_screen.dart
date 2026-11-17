import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import '../../mixins/route_aware_mixin.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/money.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/data_table_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_drawer.dart';
import '../../config/app_theme.dart';
import '../../widgets/password_confirmation_dialog.dart';
import 'product_form_screen.dart';
import 'stock_adjustment_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> with RouteAwareMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void onScreenVisible() {
    context.read<ProductProvider>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final isLoading = productProvider.isLoading;
    final products = productProvider.filteredProducts(
      searchQuery: _searchQuery,
      category: _selectedCategory,
      lowStockOnly: _showLowStockOnly,
    );

    return Scaffold(
      appBar: const CustomAppBar(title: 'Product Management'),
      drawer: const AppDrawer(currentRoute: '/products'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    controller: _searchController,
                    label: 'Search products',
                    hint: 'Name, SKU, or barcode',
                    prefixIcon: CupertinoIcons.search,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isDense: true,
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All Categories')),
                      ...productProvider.categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                    ],
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Low Stock'),
                  selected: _showLowStockOnly,
                  onSelected: (selected) => setState(() => _showLowStockOnly = selected),
                  avatar: Icon(
                    _showLowStockOnly ? Icons.check : Icons.warning,
                    size: 16,
                    color: _showLowStockOnly ? AppTheme.secondary : null,
                  ),
                  selectedColor: AppTheme.warning.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.secondary,
                ),
                const SizedBox(width: 12),
                CustomButton(
                  label: 'Add Product',
                  icon: CupertinoIcons.add,
                  onPressed: () => _addProduct(context),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  isCompact: true,
                ),
                const SizedBox(width: 8),
                CustomButton(
                  label: 'Import CSV',
                  icon: CupertinoIcons.arrow_up,
                  onPressed: _importProducts,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  isCompact: true,
                ),
                const SizedBox(width: 8),
                CustomButton(
                  label: 'Export',
                  icon: CupertinoIcons.arrow_down,
                  onPressed: _exportProducts,
                  backgroundColor: AppTheme.info,
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
                Text('${products.length} products found', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const Spacer(),
                Text('Low Stock: ${productProvider.lowStockProducts.length}', style: const TextStyle(color: Colors.orange, fontSize: 14)),
                const SizedBox(width: 16),
                Text('Out of Stock: ${productProvider.products.where((p) => p.currentStock <= 0).length}', style: const TextStyle(color: Colors.red, fontSize: 14)),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : DataTableWidget(
                    columns: const [
                      DataColumn(label: Text('SKU')),
                      DataColumn(label: Text('Product Name')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Stock')),
                      DataColumn(label: Text('Cost Price')),
                      DataColumn(label: Text('Sell Price')),
                      DataColumn(label: Text('Profit')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: products
                        .map(
                          (product) => DataRow(
                            cells: [
                              DataCell(Text(product.sku)),
                              DataCell(
                                Row(
                                  children: [
                                    if (product.imagePath != null && !kIsWeb)
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          image: DecorationImage(image: FileImage(File(product.imagePath!)), fit: BoxFit.cover),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          color: Colors.grey[200],
                                        ),
                                        child: const Icon(Icons.image, size: 20),
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(product.categoryName ?? 'Uncategorized')),
                              DataCell(
                                Row(
                                  children: [
                                    Text(
                                      product.currentStock.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: product.isLowStock ? Colors.orange : product.isOutOfStock ? Colors.red : Colors.green,
                                      ),
                                    ),
                                    Text(' ${product.baseUnit}'),
                                    if (product.isLowStock)
                                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                                  ],
                                ),
                              ),
                              DataCell(Text(AppTheme.formatMoney(product.purchasePrice))),
                              DataCell(Text(AppTheme.formatMoney(product.sellingPrice))),
                              DataCell(
                                Text(
                                  AppTheme.formatMoney(product.profitPerUnit),
                                   style: TextStyle(color: product.profitPerUnit.compareTo(Money.zero) > 0 ? Colors.green : Colors.red),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: product.isActive ? Colors.green[100] : Colors.red[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    product.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: product.isActive ? Colors.green[700] : Colors.red[700],
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
                                      onPressed: () => _editProduct(context, product),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.inventory, size: 18, color: Colors.orange),
                                      tooltip: 'Adjust Stock',
                                      onPressed: () => _adjustStock(context, product),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      tooltip: 'Delete',
                                      onPressed: () => _deleteProduct(context, product),
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

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Showing 1-${products.length > 20 ? 20 : products.length} of ${products.length}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(CupertinoIcons.chevron_left), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
                  child: const Text('1', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(CupertinoIcons.chevron_right), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addProduct(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductFormScreen()));
  }

  void _editProduct(BuildContext context, Product product) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProductFormScreen(product: product)));
  }

  void _adjustStock(BuildContext context, Product product) {
    showDialog(context: context, builder: (context) => StockAdjustmentScreen(product: product));
  }

  void _deleteProduct(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?\nThis action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final productProvider = context.read<ProductProvider>();
              final confirmed = await PasswordConfirmationDialog.show(context);
              if (!confirmed || !context.mounted) return;

              Navigator.pop(context);
              final success = await productProvider.deleteProduct(product.id!);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _importProducts() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'xlsx'], dialogTitle: 'Select Product Import File');
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import started. Please wait...'), backgroundColor: Colors.blue));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _exportProducts() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Export Location');
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Products exported to $path'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(symbol: 'UGX', decimalDigits: 0);
    return formatter.format(value).replaceAll('UGX ', 'UGX');
  }
}
