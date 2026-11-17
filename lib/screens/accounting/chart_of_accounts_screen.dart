import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/accounting_provider.dart';
import '../../models/account.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountingProvider>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart of Accounts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAccountDialog(context),
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
      drawer: const AppDrawer(currentRoute: '/accounting/chart-of-accounts'),
      body: Consumer<AccountingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final accounts = _selectedType == 'All'
              ? provider.accounts
              : provider.accounts.where((a) => a.type == _selectedType).toList();

          return Column(
            children: [
              _buildTypeFilter(),
              Expanded(
                child: ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTypeColor(account.type),
                        child: Text(account.code.substring(0, 1)),
                      ),
                      title: Text('${account.code} - ${account.name}'),
                      subtitle: Text(account.type),
                      trailing: Text(
                         'UGX ${account.balance.asDouble.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => _showEditAccountDialog(context, account),
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

  Widget _buildTypeFilter() {
    final types = ['All', 'Asset', 'Liability', 'Equity', 'Revenue', 'Expense'];
    return Container(
      padding: const EdgeInsets.all(8),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = type == _selectedType;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedType = type);
              },
            ),
          );
        },
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Asset':
        return Colors.blue;
      case 'Liability':
        return Colors.red;
      case 'Equity':
        return Colors.purple;
      case 'Revenue':
        return Colors.green;
      case 'Expense':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showAddAccountDialog(BuildContext context) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'Asset';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Add Account'),
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
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Account Code'),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Account Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['Asset', 'Liability', 'Equity', 'Revenue', 'Expense']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (value) => selectedType = value!,
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
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
              final accountingProvider = context.read<AccountingProvider>();
              final confirmed = await PasswordConfirmationDialog.show(context);
              if (!confirmed || !mounted) return;

              final account = Account(
                code: codeController.text,
                name: nameController.text,
                type: selectedType,
                description: descController.text,
              );
              await accountingProvider.createAccount(account);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditAccountDialog(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${account.code} - ${account.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${account.type}'),
            Text('Balance: UGX ${account.balance.asDouble.toStringAsFixed(0)}'),
            if (account.description != null) Text('Description: ${account.description}'),
          ],
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
