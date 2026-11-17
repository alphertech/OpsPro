import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/audit.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';

class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({super.key});

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehouseProvider>().loadStockTransfers();
      context.read<WarehouseProvider>().loadWarehouses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Transfers'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTransferDialog(context),
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
      drawer: const AppDrawer(currentRoute: '/inventory/stock-transfers'),
      body: Consumer<WarehouseProvider>(
        builder: (context, provider, _) {
          if (provider.stockTransfers.isEmpty) {
            return const Center(child: Text('No stock transfers'));
          }

          return ListView.builder(
            itemCount: provider.stockTransfers.length,
            itemBuilder: (context, index) {
              final transfer = provider.stockTransfers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    transfer.status == 'Completed' ? Icons.check_circle : Icons.pending,
                    color: transfer.status == 'Completed' ? Colors.green : Colors.orange,
                  ),
                  title: Text(transfer.transferNumber),
                  subtitle: Text('${transfer.fromWarehouseName} → ${transfer.toWarehouseName}'),
                          trailing: transfer.status == 'Pending'
                              ? TextButton(
                                  onPressed: () async {
                                    final confirmed = await PasswordConfirmationDialog.show(context);
                                    if (!confirmed) return;
                                    provider.completeStockTransfer(transfer.id!);
                                  },
                                  child: const Text('Complete'),
                                )
                      : Text(transfer.status),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddTransferDialog(BuildContext context) {
    final provider = context.read<WarehouseProvider>();
    int? fromWarehouseId;
    int? toWarehouseId;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('New Stock Transfer'),
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
              DropdownButtonFormField<int>(
                initialValue: fromWarehouseId,
                decoration: const InputDecoration(labelText: 'From Warehouse'),
                items: provider.warehouses
                    .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: (v) => fromWarehouseId = v,
              ),
              DropdownButtonFormField<int>(
                initialValue: toWarehouseId,
                decoration: const InputDecoration(labelText: 'To Warehouse'),
                items: provider.warehouses
                    .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: (v) => toWarehouseId = v,
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
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
              if (fromWarehouseId != null && toWarehouseId != null) {
                final confirmed = await PasswordConfirmationDialog.show(context);
                if (!confirmed) return;

                final from = provider.warehouses.firstWhere((w) => w.id == fromWarehouseId);
                final to = provider.warehouses.firstWhere((w) => w.id == toWarehouseId);
                await provider.createStockTransfer(StockTransfer(
                  transferNumber: 'ST${DateTime.now().millisecondsSinceEpoch}',
                  fromWarehouseId: fromWarehouseId!,
                  toWarehouseId: toWarehouseId!,
                  fromWarehouseName: from.name,
                  toWarehouseName: to.name,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                ));
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
