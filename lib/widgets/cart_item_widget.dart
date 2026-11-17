import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final int index;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: () {
                  context.read<CartProvider>().updateQuantity(index, item.quantity - 1);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                item.quantity.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.add, size: 20),
                onPressed: () {
                  context.read<CartProvider>().updateQuantity(index, item.quantity + 1);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${formatCurrency(item.price.asDouble)} / ${item.unit}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(item.quantity * item.price.asDouble - item.discount.asDouble),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(symbol: 'UGX', decimalDigits: 0);
    return formatter.format(value).replaceAll('UGX ', 'UGX');
  }
}
