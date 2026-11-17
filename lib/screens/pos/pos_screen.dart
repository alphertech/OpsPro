import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_theme.dart';
import '../../mixins/route_aware_mixin.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/security_provider.dart';
import '../../services/receipt_printer.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/cart_item_widget.dart';
import '../../widgets/cart_summary_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/password_confirmation_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> with RouteAwareMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _notesController = TextEditingController();

  bool _isProcessing = false;
  bool _isInitializing = true;
  String? _initError;
  int _selectedCategoryIndex = 0;
  String _barcodeBuffer = '';
  DateTime? _lastKeystrokeTime;
  static const _scannerThresholdMs = 50;

  List<String> get _categories =>
      const ['All', 'Seeds', 'Fertilizers', 'Chemicals', 'Tools', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initialize();
    });
    context.read<AppSettingsProvider>().addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) _syncTaxRateFromSettings();
  }

  Future<void> _initialize() async {
    try {
      final productProvider = context.read<ProductProvider>();
      final customerProvider = context.read<CustomerProvider>();

      await productProvider.ensureLoaded();
      if (!mounted) return;

      await customerProvider.ensureLoaded();
      if (!mounted) return;

      _syncTaxRateFromSettings();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = 'Failed to load data: $e';
        });
      }
    }
  }

  @override
  void onScreenVisible() {
    if (mounted) {
      context.read<ProductProvider>().ensureLoaded();
      _syncTaxRateFromSettings();
    }
  }

  void _syncTaxRateFromSettings() {
    if (!mounted) return;
    final settings = context.read<AppSettingsProvider>();
    context.read<CartProvider>().setTaxRate(settings.defaultTaxRate / 100);
  }

  @override
  void dispose() {
    context.read<AppSettingsProvider>().removeListener(_onSettingsChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  KeyEventResult _handleBarcodeScanner(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_barcodeBuffer.isNotEmpty) {
        final barcode = _barcodeBuffer;
        _barcodeBuffer = '';
        _lastKeystrokeTime = null;
        _searchByBarcode(barcode);
      }
      return KeyEventResult.handled;
    }

    final character = event.character;
    if (character == null || character.isEmpty || character.length > 1) {
      return KeyEventResult.ignored;
    }

    final now = DateTime.now();
    if (_lastKeystrokeTime != null) {
      final elapsed = now.difference(_lastKeystrokeTime!).inMilliseconds;
      if (elapsed > _scannerThresholdMs) {
        _barcodeBuffer = '';
      }
    }
    _lastKeystrokeTime = now;
    _barcodeBuffer += character;
    return KeyEventResult.handled;
  }

  Future<void> _searchByBarcode(String barcode) async {
    if (!mounted) return;

    try {
      final productProvider = context.read<ProductProvider>();
      final products = productProvider.products.where((p) {
        return p.barcode?.toLowerCase() == barcode.toLowerCase() && p.isActive;
      }).toList();

      if (products.isEmpty) {
        _showSnackBar('Product not found for scanned barcode', Colors.red);
        return;
      }

      _addProductToCart(products.first);
      _searchController.clear();
      _searchFocusNode.requestFocus();
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _addProductToCart(Product product) {
    try {
      context.read<CartProvider>().addItem(product);
      _showSnackBar('Added: ${product.name}', Colors.green);
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  List<Product> _getFilteredProducts(ProductProvider provider) {
    try {
      var products = provider.products.where((p) => p.isActive).toList();

      if (_selectedCategoryIndex > 0 && _selectedCategoryIndex < _categories.length) {
        final selectedCategory = _categories[_selectedCategoryIndex];
        products = products
            .where((p) =>
                p.categoryName?.toLowerCase() == selectedCategory.toLowerCase())
            .toList();
      }

      final searchText = _searchController.text.toLowerCase();
      if (searchText.isNotEmpty) {
        products = products.where((p) {
          return p.name.toLowerCase().contains(searchText) ||
              p.sku.toLowerCase().contains(searchText) ||
              (p.barcode?.toLowerCase().contains(searchText) ?? false);
        }).toList();
      }

      return products;
    } catch (e) {
      return [];
    }
  }

  Future<void> _processSale() async {
    if (!mounted) return;

    final cartProvider = context.read<CartProvider>();
    final securityProvider = context.read<SecurityProvider>();

    if (cartProvider.isEmpty) {
      _showSnackBar('Cart is empty. Add items before processing.', Colors.orange);
      return;
    }

    if (cartProvider.paymentMethod == 'Credit' &&
        cartProvider.selectedCustomerId == null) {
      _showSnackBar('Please select a customer for credit sale.', Colors.orange);
      return;
    }

    if (cartProvider.paymentMethod == 'Credit' &&
        cartProvider.selectedCustomerId != null) {
      final customerProvider = context.read<CustomerProvider>();
      final customer = customerProvider.customers.firstWhere(
        (c) => c.id == cartProvider.selectedCustomerId,
        orElse: () => Customer(name: ''),
      );

      if (customer.id != null &&
          customer.creditLimit > 0 &&
          cartProvider.total.asDouble >
              (customer.creditLimit - customer.currentBalance)) {
        _showSnackBar(
          'Credit limit exceeded. Available: ${AppTheme.formatCurrency(customer.creditLimit - customer.currentBalance)}',
          Colors.red,
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final confirmed = await PasswordConfirmationDialog.show(context, forceVerification: true);
      if (!confirmed || !mounted) {
        setState(() => _isProcessing = false);
        return;
      }

      final sale = await cartProvider.toSale(
        userId: securityProvider.currentUser?.id ?? 0,
        userName: securityProvider.currentUser?.displayName ?? 'Cashier',
      );

      if (!mounted) return;

      final saleProvider = context.read<SaleProvider>();
      final savedSale = await saleProvider.createSale(sale);

      if (savedSale != null && mounted) {
        cartProvider.clear();
        _notesController.clear();
        _searchController.clear();
        _searchFocusNode.requestFocus();
        _showSaleCompleteDialog(savedSale);
      } else if (mounted) {
        _showSnackBar('Failed to save sale. Please try again.', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to process sale: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSaleCompleteDialog(Sale sale) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('Sale Completed!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(sale.invoiceNumber,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryRow('Total Amount:', AppTheme.formatMoney(sale.totalAmount)),
            _buildSummaryRow('Amount Paid:', AppTheme.formatMoney(sale.amountPaid)),
            if (sale.isCredit)
              _buildSummaryRow(
                'Balance Due:',
                AppTheme.formatMoney(sale.balanceDue),
                valueColor: Colors.orange,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Print Receipt',
                    icon: Icons.print,
                    onPressed: () {
                      Navigator.pop(context);
                      _printReceipt(sale);
                    },
                    backgroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    label: 'OK',
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Future<void> _printReceipt(Sale sale) async {
    if (!mounted) return;

    try {
      String printerIp = ReceiptPrinter.defaultPrinterIp;
      try {
        final prefs = await SharedPreferences.getInstance();
        printerIp =
            prefs.getString('printer_ip') ?? ReceiptPrinter.defaultPrinterIp;
      } catch (_) {}

      final success =
          await ReceiptPrinter.printReceipt(sale, printerIp: printerIp);

      if (!success && mounted) {
        _showSnackBar(
          'Could not print receipt. Check the printer connection.',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error printing receipt: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        appBar: CustomAppBar(
          title: 'Point of Sale',
          showMenuButton: true,
          showLockButton: true,
        ),
        drawer: AppDrawer(currentRoute: '/pos'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading Point of Sale...'),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Point of Sale',
          showMenuButton: true,
          showLockButton: true,
        ),
        drawer: const AppDrawer(currentRoute: '/pos'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Initialization Failed',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(_initError!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Retry',
                  icon: Icons.refresh,
                  onPressed: () {
                    setState(() {
                      _isInitializing = true;
                      _initError = null;
                    });
                    _initialize();
                  },
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Point of Sale',
        showMenuButton: true,
        showLockButton: true,
      ),
      drawer: const AppDrawer(currentRoute: '/pos'),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildProductGrid(),
          ),
          Expanded(
            flex: 2,
            child: _buildCartSection(),
          ),
        ],
      ),
      bottomNavigationBar: _buildShortcutsBar(),
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final filteredProducts = _getFilteredProducts(productProvider);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomTextField(
                controller: _searchController,
                label: 'Search Products',
                prefixIcon: Icons.search,
                hint: 'Name, SKU, or Barcode',
                onChanged: (_) => setState(() {}),
              ),
            ),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(_categories[index]),
                      selected: _selectedCategoryIndex == index,
                      onSelected: (selected) {
                        setState(() => _selectedCategoryIndex = index);
                      },
                      selectedColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      checkmarkColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      labelStyle: Theme.of(context).chipTheme.labelStyle
                          ?.copyWith(
                        color: _selectedCategoryIndex == index
                            ? Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Focus(
                focusNode: _searchFocusNode,
                autofocus: true,
                onKeyEvent: _handleBarcodeScanner,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final isOutOfStock = product.currentStock <= 0;
                    return _buildProductCard(product, isOutOfStock);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Product product, bool isOutOfStock) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOutOfStock ? Colors.red[300]! : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isOutOfStock ? null : () => _addProductToCart(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getProductIcon(product.categoryName ?? ''),
                size: 32,
                color: isOutOfStock
                    ? Colors.grey
                    : Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isOutOfStock ? Colors.grey : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppTheme.formatMoney(product.sellingPrice),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isOutOfStock
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${product.currentStock.toStringAsFixed(1)} ${product.baseUnit}',
                style: TextStyle(
                  fontSize: 11,
                  color: isOutOfStock ? Colors.red : Colors.grey[600],
                ),
              ),
              if (isOutOfStock)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Out of Stock',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSection() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(left: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            children: [
              _buildCartHeader(cartProvider),
              Expanded(child: _buildCartItems(cartProvider)),
              CartSummaryWidget(
                onComplete: _isProcessing ? null : _processSale,
                isProcessing: _isProcessing,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartHeader(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_cart,
              color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            'Cart (${cartProvider.itemCount} items)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: cartProvider.isEmpty
                ? null
                : () {
                    context.read<CartProvider>().clear();
                    _notesController.clear();
                    setState(() {});
                  },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Clear All'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(CartProvider cartProvider) {
    if (cartProvider.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Cart is empty',
                style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            const SizedBox(height: 8),
            Text('Search and tap products to add',
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: cartProvider.items.length,
      itemBuilder: (context, index) {
        final item = cartProvider.items[index];
        return CartItemWidget(
          item: item,
          index: index,
          onRemove: () {
            cartProvider.removeItem(index);
          },
        );
      },
    );
  }

  Widget _buildShortcutsBar() {
    return BottomAppBar(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildShortcutHint('F2', 'Search'),
            const SizedBox(width: 16),
            _buildShortcutHint('+', 'Add Qty'),
            const SizedBox(width: 16),
            _buildShortcutHint('-', 'Remove Qty'),
            const SizedBox(width: 16),
            _buildShortcutHint('F12', 'Complete Sale'),
            const SizedBox(width: 16),
            _buildShortcutHint('Esc', 'Clear Cart'),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutHint(String key, String action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Text(key,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              )),
        ),
        const SizedBox(width: 4),
        Text(action, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  IconData _getProductIcon(String category) {
    switch (category.toLowerCase()) {
      case 'seeds':
        return Icons.grass;
      case 'fertilizers':
        return Icons.science;
      case 'chemicals':
        return Icons.biotech;
      case 'tools':
        return Icons.handyman;
      default:
        return Icons.inventory;
    }
  }
}
