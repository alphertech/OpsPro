import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_button.dart';

class CartSummaryWidget extends StatelessWidget {
  final VoidCallback? onComplete;
  final bool isProcessing;

  const CartSummaryWidget({
    super.key,
    this.onComplete,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final formatter = NumberFormat.currency(symbol: 'UGX', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text(formatter.format(cart.subtotal.asDouble)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax (${(cart.taxRate * 100).toStringAsFixed(0)}%):'),
              Text(formatter.format(cart.taxAmount.asDouble)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount:'),
              Text(
                formatter.format(-cart.totalDiscount.asDouble),
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                formatter.format(cart.total.asDouble),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Payment:'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: cart.paymentMethod,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                    DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'Credit', child: Text('Credit (Debt)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      context.read<CartProvider>().setPaymentMethod(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: isProcessing ? 'Processing...' : 'Complete Sale',
            icon: Icons.check_circle,
            onPressed: isProcessing ? null : onComplete,
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
