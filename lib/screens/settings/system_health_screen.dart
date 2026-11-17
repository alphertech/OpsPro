import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/system_health_provider.dart';
import '../../widgets/app_drawer.dart';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuditProvider>().loadAuditLogs(limit: 50);
      context.read<SystemHealthProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Health'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (context.watch<SystemHealthProvider>().isRefreshing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<AuditProvider>().loadAuditLogs(limit: 50);
                context.read<SystemHealthProvider>().refresh();
              },
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
      drawer: const AppDrawer(currentRoute: '/settings/system-health'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthCards(),
            const SizedBox(height: 24),
            _buildAuditLogSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCards() {
    final health = context.watch<SystemHealthProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('System Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildHealthCard('Database', health.dbConnected ? 'Connected' : 'Disconnected', Icons.storage, health.dbConnected ? Colors.green : Colors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHealthCard('Storage', health.storageStatus, Icons.sd_storage, _statusColor(health.storageStatus)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildHealthCard('Memory', health.memoryStatus, Icons.memory, _statusColor(health.memoryStatus)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHealthCard('CPU', health.cpuStatus, Icons.speed, _statusColor(health.cpuStatus)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthCard(String title, String status, IconData icon, Color color) {
    final health = context.watch<SystemHealthProvider>();
    String? detail;
    switch (title) {
      case 'Storage':
        detail = health.storageDetail;
        break;
      case 'Memory':
        detail = health.memoryDetail;
        break;
      case 'CPU':
        detail = health.cpuDetail;
        break;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            if (detail != null && detail.isNotEmpty && detail != status)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  detail,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Consumer<AuditProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.auditLogs.isEmpty) {
              return const Center(child: Text('No recent activity'));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.auditLogs.length,
              itemBuilder: (context, index) {
                final log = provider.auditLogs[index];
                return ListTile(
                  leading: Icon(
                    _getActionIcon(log.action),
                    color: _getActionColor(log.action),
                  ),
                  title: Text('${log.tableName} - ${log.action}'),
                  subtitle: Text(log.userName ?? 'System'),
                  trailing: Text(
                    log.createdAt.toString().split(' ')[0],
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'connected':
      case 'available':
      case 'normal':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'critical':
      case 'disconnected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
