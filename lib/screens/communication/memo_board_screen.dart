import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/audit.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';

class MemoBoardScreen extends StatefulWidget {
  const MemoBoardScreen({super.key});

  @override
  State<MemoBoardScreen> createState() => _MemoBoardScreenState();
}

class _MemoBoardScreenState extends State<MemoBoardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunicationProvider>().loadMemos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internal Memos'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMemoDialog(context),
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
      drawer: const AppDrawer(currentRoute: '/communication/memo-board'),
      body: Consumer<CommunicationProvider>(
        builder: (context, provider, _) {
          if (provider.memos.isEmpty) {
            return const Center(child: Text('No memos'));
          }

          return ListView.builder(
            itemCount: provider.activeMemos.length,
            itemBuilder: (context, index) {
              final memo = provider.activeMemos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    memo.isPinned ? Icons.push_pin : Icons.note,
                    color: memo.priority == 'High' ? Colors.red : Colors.blue,
                  ),
                  title: Text(memo.title),
                  subtitle: Text('${memo.createdByName} - ${memo.createdAt.toString().split(' ')[0]}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await PasswordConfirmationDialog.show(context);
                      if (!confirmed || !mounted) return;
                      provider.deleteMemo(memo.id!);
                    },
                  ),
                  onTap: () => _showMemoDetail(context, memo),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddMemoDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String priority = 'Normal';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('New Memo'),
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
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 4,
              ),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['Normal', 'High', 'Low']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => priority = v!,
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
              final communicationProvider = context.read<CommunicationProvider>();
              final confirmed = await PasswordConfirmationDialog.show(context);
              if (!confirmed || !mounted) return;

              await communicationProvider.createMemo(
                title: titleController.text,
                content: contentController.text,
                createdBy: 1,
                createdByName: 'Admin',
                priority: priority,
              );
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showMemoDetail(BuildContext context, InternalMemo memo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(memo.title)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(memo.content),
              const SizedBox(height: 16),
              Text('By: ${memo.createdByName}', style: const TextStyle(fontSize: 12)),
              Text('Date: ${memo.createdAt.toString().split(' ')[0]}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}