import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';

class CustomerPaymentScreen extends StatefulWidget {
  const CustomerPaymentScreen({super.key});

  @override
  State<CustomerPaymentScreen> createState() => _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends State<CustomerPaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Payments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
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
      drawer: const AppDrawer(currentRoute: '/customers/payment'),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          final customersWithBalance = provider.customersWithOutstandingBalance;

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (customersWithBalance.isEmpty) {
            return const Center(
                child: Text('No customers with outstanding balances'));
          }

          return ListView.builder(
            itemCount: customersWithBalance.length,
            itemBuilder: (context, index) {
              final customer = customersWithBalance[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: customer.currentBalance > 0
                        ? Colors.orange
                        : Colors.green,
                    child: Text(customer.name[0]),
                  ),
                  title: Text(customer.name),
                  subtitle: Text('Phone: ${customer.phone ?? 'N/A'}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'UGX ${customer.currentBalance.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => _showPaymentDialog(context, customer),
                        child: const Text('Record Payment'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Customer customer) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Record Payment - ${customer.name}'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Outstanding: UGX ${customer.currentBalance.toStringAsFixed(0)}'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Payment Amount'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration:
                    const InputDecoration(labelText: 'Notes (Optional)'),
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
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.red),
                );
                return;
              }

              if (amount > customer.currentBalance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Amount exceeds outstanding balance'),
                      backgroundColor: Colors.red),
                );
                return;
              }

              final customerProvider = context.read<CustomerProvider>();
              final confirmed = await PasswordConfirmationDialog.show(context);
              if (!confirmed || !mounted) return;

              final newBalance = customer.currentBalance - amount;
              final success = await customerProvider.updateCustomerBalance(
                  customer.id!, newBalance);

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Payment of UGX ${amount.toStringAsFixed(0)} recorded'),
                        backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Failed to record payment'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }
}
