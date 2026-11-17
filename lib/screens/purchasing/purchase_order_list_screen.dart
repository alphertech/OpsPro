import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/purchase_order_provider.dart';
import '../../config/routes.dart';
import '../../services/navigation_service.dart';
import '../../widgets/app_drawer.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() => _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseOrderProvider>().loadPurchaseOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => NavigationService.navigateTo(AppRoutes.purchaseOrderAdd),
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
      drawer: const AppDrawer(currentRoute: '/purchasing/orders'),
      body: Consumer<PurchaseOrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pos = _selectedStatus == 'All'
              ? provider.purchaseOrders
              : provider.purchaseOrders.where((po) => po.status == _selectedStatus).toList();

          return Column(
            children: [
              _buildStatusFilter(),
              Expanded(
                child: pos.isEmpty
                    ? const Center(child: Text('No purchase orders'))
                    : ListView.builder(
                        itemCount: pos.length,
                        itemBuilder: (context, index) {
                          final po = pos[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(po.status),
                                child: Text(po.poNumber.substring(0, 2)),
                              ),
                              title: Text(po.poNumber),
                              subtitle: Text('${po.supplierName} - ${po.orderDate.toString().split(' ')[0]}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('UGX ${po.totalAmount.asDouble.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(po.status, style: TextStyle(color: _getStatusColor(po.status))),
                                ],
                              ),
                              onTap: () => NavigationService.navigateTo(
                                AppRoutes.purchaseOrderEdit,
                                arguments: {'purchaseOrder': po},
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = ['All', 'Draft', 'Sent', 'Partial Receipt', 'Completed'];
    return Container(
      padding: const EdgeInsets.all(8),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = status == _selectedStatus;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) => setState(() => _selectedStatus = status),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Draft':
        return Colors.grey;
      case 'Sent':
        return Colors.blue;
      case 'Partial Receipt':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}