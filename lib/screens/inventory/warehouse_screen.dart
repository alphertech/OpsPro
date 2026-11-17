import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/audit.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehouseProvider>().loadWarehouses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouses'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWarehouseDialog(context),
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
      drawer: const AppDrawer(currentRoute: '/inventory/warehouses'),
      body: Consumer<WarehouseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.warehouses.isEmpty) {
            return const Center(child: Text('No warehouses'));
          }

          return ListView.builder(
            itemCount: provider.warehouses.length,
            itemBuilder: (context, index) {
              final warehouse = provider.warehouses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: warehouse.isDefault ? Colors.green : Colors.grey,
                    child: const Icon(Icons.warehouse, color: Colors.white),
                  ),
                  title: Text(warehouse.name),
                  subtitle: Text('${warehouse.code ?? ''} - ${warehouse.address ?? ''}'),
                  trailing: warehouse.isDefault
                      ? const Chip(label: Text('Default'), backgroundColor: Colors.green)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddWarehouseDialog(BuildContext context) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Add Warehouse'),
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
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
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
              final warehouseProvider = context.read<WarehouseProvider>();
              final confirmed = await PasswordConfirmationDialog.show(context);
              if (!confirmed || !mounted) return;

              await warehouseProvider.createWarehouse(Warehouse(
                name: nameController.text,
                code: codeController.text.isNotEmpty ? codeController.text : null,
                address: addressController.text.isNotEmpty ? addressController.text : null,
              ));
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}