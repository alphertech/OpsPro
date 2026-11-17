import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/purchase_order_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/purchase_order.dart';
import '../../utils/money.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';

class PurchaseOrderFormScreen extends StatefulWidget {
  final PurchaseOrder? purchaseOrder;

  const PurchaseOrderFormScreen({super.key, this.purchaseOrder});

  @override
  State<PurchaseOrderFormScreen> createState() => _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends State<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _supplierId;
  DateTime _orderDate = DateTime.now();
  final _notesController = TextEditingController();
  final _shippingController = TextEditingController(text: '0');
  final _insuranceController = TextEditingController(text: '0');
  final _customsController = TextEditingController(text: '0');
  final _otherController = TextEditingController(text: '0');
  final List<PurchaseOrderItem> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().loadSuppliers();
      context.read<ProductProvider>().loadProducts();
    });
    if (widget.purchaseOrder != null) {
      _supplierId = widget.purchaseOrder!.supplierId;
      _orderDate = widget.purchaseOrder!.orderDate;
      _notesController.text = widget.purchaseOrder!.notes ?? '';
      _shippingController.text = widget.purchaseOrder!.shippingCost.toString();
      _insuranceController.text = widget.purchaseOrder!.insuranceCost.toString();
      _customsController.text = widget.purchaseOrder!.customsFee.toString();
      _otherController.text = widget.purchaseOrder!.otherCosts.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purchaseOrder == null ? 'New Purchase Order' : 'Edit Purchase Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePurchaseOrder,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerRight,
            child: const Text(
              'Plexus',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/purchasing/orders/add'),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<SupplierProvider>(
                      builder: (context, supplierProvider, _) {
                        return DropdownButtonFormField<int>(
                          initialValue: _supplierId,
                          decoration: const InputDecoration(labelText: 'Supplier'),
                          items: supplierProvider.suppliers
                              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                              .toList(),
                          onChanged: (v) => setState(() => _supplierId = v),
                          validator: (v) => v == null ? 'Select supplier' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _shippingController,
                            decoration: const InputDecoration(labelText: 'Shipping Cost'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _insuranceController,
                            decoration: const InputDecoration(labelText: 'Insurance'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customsController,
                            decoration: const InputDecoration(labelText: 'Customs Fee'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _otherController,
                            decoration: const InputDecoration(labelText: 'Other Costs'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Card(
                        child: ListTile(
                          title: Text(item.productName),
                          subtitle: Text('${item.quantity} ${item.unit} @ UGX ${item.unitPrice.asDouble.toStringAsFixed(0)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('UGX ${item.totalPrice.asDouble.toStringAsFixed(0)}'),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => _items.removeAt(index)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    'UGX ${_calculateTotal().toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotal() {
    double subtotal = _items.fold(0, (sum, item) => sum + item.totalPrice.asDouble);
    double additional = (double.tryParse(_shippingController.text) ?? 0) +
        (double.tryParse(_insuranceController.text) ?? 0) +
        (double.tryParse(_customsController.text) ?? 0) +
        (double.tryParse(_otherController.text) ?? 0);
    return subtotal + additional;
  }

  void _addItem() {
    final productProvider = context.read<ProductProvider>();
    int? productId;
    double quantity = 1;
    double unitPrice = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: productId,
                decoration: const InputDecoration(labelText: 'Product'),
                items: productProvider.products
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (v) {
                  productId = v;
                  if (v != null) {
                    final product = productProvider.getProductById(v);
                   if (product != null) {
                     unitPrice = product.purchasePrice.asDouble;
                   }
                  }
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                onChanged: (v) => quantity = double.tryParse(v) ?? 1,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Unit Price'),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: unitPrice.toString()),
                onChanged: (v) => unitPrice = double.tryParse(v) ?? 0,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (productId != null) {
                final product = productProvider.getProductById(productId!);
                setState(() {
                  _items.add(PurchaseOrderItem(
                    productId: productId!,
                    productName: product?.name ?? '',
                    productSku: product?.sku,
                    quantity: quantity,
                    unit: product?.baseUnit ?? 'Pieces',
                    unitPrice: Money.fromDouble(unitPrice),
                    totalPrice: Money.fromDouble(quantity * unitPrice),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _savePurchaseOrder() async {
    if (_supplierId == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select supplier and add items')),
      );
      return;
    }

    final confirmed = await PasswordConfirmationDialog.show(context);
    if (!confirmed || !mounted) return;

    final supplierProvider = context.read<SupplierProvider>();
    final supplier = supplierProvider.suppliers.firstWhere((s) => s.id == _supplierId);

    final subtotal = _items.fold(0.0, (sum, item) => sum + item.totalPrice.asDouble);
    final total = _calculateTotal();

    final po = PurchaseOrder(
      id: widget.purchaseOrder?.id,
      poNumber: widget.purchaseOrder?.poNumber ?? 'PO${DateTime.now().millisecondsSinceEpoch}',
      supplierId: _supplierId!,
      supplierName: supplier.name,
      orderDate: _orderDate,
      status: widget.purchaseOrder?.status ?? 'Draft',
      subtotal: Money.fromDouble(subtotal),
      shippingCost: Money.fromDouble(double.tryParse(_shippingController.text) ?? 0),
      insuranceCost: Money.fromDouble(double.tryParse(_insuranceController.text) ?? 0),
      customsFee: Money.fromDouble(double.tryParse(_customsController.text) ?? 0),
      otherCosts: Money.fromDouble(double.tryParse(_otherController.text) ?? 0),
      totalAmount: Money.fromDouble(total),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final provider = context.read<PurchaseOrderProvider>();
    bool success;
    if (widget.purchaseOrder == null) {
      success = await provider.createPurchaseOrder(po, _items);
    } else {
      success = await provider.updatePurchaseOrder(po);
    }

    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}
