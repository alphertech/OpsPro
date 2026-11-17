import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';

class EmailQueueScreen extends StatefulWidget {
  const EmailQueueScreen({super.key});

  @override
  State<EmailQueueScreen> createState() => _EmailQueueScreenState();
}

class _EmailQueueScreenState extends State<EmailQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunicationProvider>().loadEmailQueue();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Queue'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEmailDialog(context),
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
      drawer: const AppDrawer(currentRoute: '/communication/email-queue'),
      body: Consumer<CommunicationProvider>(
        builder: (context, provider, _) {
          if (provider.emailQueue.isEmpty) {
            return const Center(child: Text('No emails in queue'));
          }

          return ListView.builder(
            itemCount: provider.emailQueue.length,
            itemBuilder: (context, index) {
              final email = provider.emailQueue[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    email.status == 'Sent' ? Icons.check_circle : Icons.pending,
                    color: email.status == 'Sent' ? Colors.green : Colors.orange,
                  ),
                  title: Text(email.subject),
                  subtitle: Text('To: ${email.recipient}'),
                  trailing: Text(email.status),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddEmailDialog(BuildContext context) {
    final recipientController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Queue Email'),
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
                controller: recipientController,
                decoration: const InputDecoration(labelText: 'Recipient'),
              ),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 4,
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

              await communicationProvider.queueEmail(
                recipient: recipientController.text,
                subject: subjectController.text,
                body: bodyController.text,
              );
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Queue'),
          ),
        ],
      ),
    );
  }
}