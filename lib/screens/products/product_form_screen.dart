import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../utils/money.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';
import '../../utils/validators.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _averageCostController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _vipPriceController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _minimumStockController = TextEditingController();
  final _maximumStockController = TextEditingController();
  final _baseUnitController = TextEditingController();
  final _sellingUnitController = TextEditingController();
  final _conversionFactorController = TextEditingController();
  final _weightController = TextEditingController();
  final _volumeController = TextEditingController();
  final _locationController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();

  int _selectedCategoryId = 0;
  int? _selectedSupplierId;
  bool _isActive = true;
  DateTime? _manufacturingDate;
  DateTime? _expiryDate;
  bool _isLoading = false;

  final List<String> _units = ['Kg', 'g', 'L', 'mL', 'Pieces', 'Bags', 'Boxes', 'Crates', 'Bundles'];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _populateFields(widget.product!);
    } else {
      _generateSKU();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().ensureLoaded();
    });
  }

  void _populateFields(Product product) {
    _nameController.text = product.name;
    _skuController.text = product.sku;
    _barcodeController.text = product.barcode ?? '';
    _categoryController.text = product.categoryName ?? '';
    _selectedCategoryId = product.categoryId;
    _purchasePriceController.text = product.purchasePrice.asDouble.toStringAsFixed(2);
    _averageCostController.text = product.averageCost.asDouble.toStringAsFixed(2);
    _sellingPriceController.text = product.sellingPrice.asDouble.toStringAsFixed(2);
    _wholesalePriceController.text = product.wholesalePrice.asDouble.toStringAsFixed(2);
    _vipPriceController.text = (product.vipPrice?.asDouble ?? 0).toStringAsFixed(2);
    _currentStockController.text = product.currentStock.toStringAsFixed(1);
    _minimumStockController.text = product.minimumStock.toStringAsFixed(1);
    _maximumStockController.text = product.maximumStock.toStringAsFixed(1);
    _baseUnitController.text = product.baseUnit;
    _sellingUnitController.text = product.sellingUnit;
    _conversionFactorController.text = product.conversionFactor.toStringAsFixed(2);
    _weightController.text = (product.weightPerUnit ?? 0).toStringAsFixed(2);
    _volumeController.text = (product.volumePerUnit ?? 0).toStringAsFixed(2);
    _locationController.text = product.location ?? '';
    _batchNumberController.text = product.batchNumber ?? '';
    _selectedSupplierId = product.supplierId;
    _isActive = product.isActive;
    _manufacturingDate = product.manufacturingDate;
    _expiryDate = product.expiryDate;
    if (product.expiryDate != null) {
      _expiryDateController.text = DateFormat('yyyy-MM-dd').format(product.expiryDate!);
    }
  }

  void _generateSKU() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    _skuController.text = 'PRD-$timestamp';
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await PasswordConfirmationDialog.show(context);
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        categoryId: _selectedCategoryId,
        categoryName: _categoryController.text.trim(),
        purchasePrice: Money.fromDouble(double.parse(_purchasePriceController.text)),
        averageCost: Money.fromDouble(double.parse(_averageCostController.text)),
        sellingPrice: Money.fromDouble(double.parse(_sellingPriceController.text)),
        wholesalePrice: Money.fromDouble(double.parse(_wholesalePriceController.text)),
        vipPrice: _vipPriceController.text.isNotEmpty ? Money.fromDouble(double.parse(_vipPriceController.text)) : null,
        currentStock: double.parse(_currentStockController.text),
        minimumStock: double.parse(_minimumStockController.text),
        maximumStock: double.parse(_maximumStockController.text),
        baseUnit: _baseUnitController.text,
        sellingUnit: _sellingUnitController.text,
        conversionFactor: double.parse(_conversionFactorController.text),
        weightPerUnit: _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
        volumePerUnit: _volumeController.text.isNotEmpty ? double.parse(_volumeController.text) : null,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        batchNumber: _batchNumberController.text.trim().isEmpty ? null : _batchNumberController.text.trim(),
        manufacturingDate: _manufacturingDate,
        expiryDate: _expiryDate,
        supplierId: _selectedSupplierId,
        isActive: _isActive,
      );

      final success = widget.product == null
          ? await context.read<ProductProvider>().createProduct(product)
          : await context.read<ProductProvider>().updateProduct(product);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null ? 'Product created successfully!' : 'Product updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isExpiry) async {
    final initialDate = isExpiry ? _expiryDate : _manufacturingDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
          _expiryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _manufacturingDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<SupplierProvider>().suppliers;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add New Product' : 'Edit Product'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          if (widget.product != null)
            IconButton(
              icon: AppIcon(icon: _isActive ? CupertinoIcons.eye : CupertinoIcons.eye_slash),
              onPressed: () => setState(() => _isActive = !_isActive),
              tooltip: _isActive ? 'Deactivate Product' : 'Activate Product',
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
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/products/add'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Basic Information', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              controller: _nameController,
                              label: 'Product Name *',
                              validator: (value) => Validators.required(value, 'Product name'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _skuController,
                              label: 'SKU *',
                              validator: (value) => Validators.required(value, 'SKU'),
                              enabled: widget.product == null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _barcodeController,
                              label: 'Barcode',
                              hint: 'Optional',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _categoryController,
                              label: 'Category *',
                              hint: 'e.g., Seeds, Fertilizers',
                              validator: (value) => Validators.required(value, 'Category'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _baseUnitController.text.isNotEmpty ? _baseUnitController.text : null,
                              decoration: const InputDecoration(
                                labelText: 'Base Unit *',
                                border: OutlineInputBorder(),
                              ),
                              items: _units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                              onChanged: (value) => _baseUnitController.text = value ?? '',
                              validator: (value) => value == null ? 'Select base unit' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _locationController,
                              label: 'Storage Location',
                              hint: 'e.g., Aisle-3, Rack-B',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pricing & Costs', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _purchasePriceController,
                              label: 'Purchase Price *',
                              prefixText: 'UGX ',
                              keyboardType: TextInputType.number,
                              validator: (value) => Validators.isNumber(value, 'Purchase price'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _averageCostController,
                              label: 'Average Cost *',
                              prefixText: 'UGX ',
                              keyboardType: TextInputType.number,
                              validator: (value) => Validators.isNumber(value, 'Average cost'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _sellingPriceController,
                              label: 'Selling Price *',
                              prefixText: 'UGX ',
                              keyboardType: TextInputType.number,
                              validator: (value) => Validators.isNumber(value, 'Selling price'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _wholesalePriceController,
                              label: 'Wholesale Price',
                              prefixText: 'UGX ',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _vipPriceController,
                              label: 'VIP Price',
                              prefixText: 'UGX ',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stock Management', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _currentStockController,
                              label: 'Current Stock *',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) => Validators.isNumber(value, 'Stock quantity'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _minimumStockController,
                              label: 'Minimum Stock *',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) => Validators.isNumber(value, 'Minimum stock'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _maximumStockController,
                              label: 'Maximum Stock',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _sellingUnitController,
                              label: 'Selling Unit',
                              hint: 'Same as base unit',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _conversionFactorController,
                              label: 'Conversion Factor',
                              hint: '1 Base = X Selling',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _weightController,
                              label: 'Weight per Unit (Kg)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Batch & Expiry Tracking', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _batchNumberController,
                              label: 'Batch Number',
                              hint: 'Optional',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: CustomTextField(
                                controller: TextEditingController(
                                  text: _manufacturingDate != null ? DateFormat('yyyy-MM-dd').format(_manufacturingDate!) : '',
                                ),
                                label: 'Manufacturing Date',
                                hint: 'Tap to select',
                                enabled: false,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: CustomTextField(
                                controller: _expiryDateController,
                                label: 'Expiry Date *',
                                hint: 'Tap to select',
                                enabled: false,
                                validator: (value) {
                                  if (_expiryDate == null) return 'Please select expiry date';
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Supplier Information', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedSupplierId,
                              decoration: const InputDecoration(
                                labelText: 'Preferred Supplier',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Select Supplier')),
                                ...suppliers.map((supplier) => DropdownMenuItem(value: supplier.id, child: Text(supplier.name))),
                              ],
                              onChanged: (value) => setState(() => _selectedSupplierId = value),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: TextEditingController(
                                text: _selectedSupplierId != null ? suppliers.firstWhere((s) => s.id == _selectedSupplierId).name : '',
                              ),
                              label: 'Supplier Name',
                              enabled: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      isFullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      label: _isLoading ? 'Saving...' : 'Save Product',
                      icon: CupertinoIcons.cloud_download,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _saveProduct,
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      isFullWidth: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _averageCostController.dispose();
    _sellingPriceController.dispose();
    _wholesalePriceController.dispose();
    _vipPriceController.dispose();
    _currentStockController.dispose();
    _minimumStockController.dispose();
    _maximumStockController.dispose();
    _baseUnitController.dispose();
    _sellingUnitController.dispose();
    _conversionFactorController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _locationController.dispose();
    _batchNumberController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }
}
