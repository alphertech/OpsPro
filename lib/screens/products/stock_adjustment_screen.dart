import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../widgets/password_confirmation_dialog.dart';

class StockAdjustmentScreen extends StatefulWidget {
  final Product product;

  const StockAdjustmentScreen({super.key, required this.product});

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _noteController;
  String _adjustmentType = 'add';

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveStockAdjustment() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.parse(_quantityController.text);
    double newStock;
    if (_adjustmentType == 'add') {
      newStock = widget.product.currentStock + quantity;
    } else if (_adjustmentType == 'subtract') {
      newStock = widget.product.currentStock - quantity;
    } else {
      newStock = quantity;
    }

    final updatedProduct = widget.product.copyWith(
      currentStock: newStock,
    );

    final confirmed = await PasswordConfirmationDialog.show(context);
    if (!confirmed || !mounted) return;

    final success = await context.read<ProductProvider>().updateProduct(updatedProduct);

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock adjusted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to adjust stock'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Stock - ${widget.product.name}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Stock: ${widget.product.currentStock.toStringAsFixed(1)} ${widget.product.baseUnit}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'add',
                    label: Text('Add'),
                    icon: Icon(CupertinoIcons.add),
                  ),
                  ButtonSegment(
                    value: 'subtract',
                    label: Text('Subtract'),
                    icon: Icon(Icons.remove),
                  ),
                    ButtonSegment(
                      value: 'set',
                      label: Text('Set'),
                      icon: Icon(Icons.edit),
                    ),
                ],
                selected: {_adjustmentType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _adjustmentType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity';
                  }
                  final quantity = double.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveStockAdjustment,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
