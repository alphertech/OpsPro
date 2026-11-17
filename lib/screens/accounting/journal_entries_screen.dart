import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/accounting_provider.dart';
import '../../models/account.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';

class JournalEntriesScreen extends StatefulWidget {
  const JournalEntriesScreen({super.key});

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountingProvider>().loadJournalEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entries'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEntryDialog(context),
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
      drawer: const AppDrawer(currentRoute: '/accounting/journal-entries'),
      body: Consumer<AccountingProvider>(
        builder: (context, provider, _) {
          if (provider.journalEntries.isEmpty) {
            return const Center(child: Text('No journal entries yet'));
          }

          return ListView.builder(
            itemCount: provider.journalEntries.length,
            itemBuilder: (context, index) {
              final entry = provider.journalEntries[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(entry.description),
                  subtitle: Text('${entry.entryNumber} - ${entry.entryDate.toString().split(' ')[0]}'),
                  trailing: Text(
                    'UGX ${entry.amount.asDouble.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    final provider = context.read<AccountingProvider>();
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final refController = TextEditingController();
    int? debitAccountId;
    int? creditAccountId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('New Journal Entry'),
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
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: debitAccountId,
                decoration: const InputDecoration(labelText: 'Debit Account'),
                items: provider.accounts
                    .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.code} - ${a.name}')))
                    .toList(),
                onChanged: (value) => debitAccountId = value,
              ),
              DropdownButtonFormField<int>(
                initialValue: creditAccountId,
                decoration: const InputDecoration(labelText: 'Credit Account'),
                items: provider.accounts
                    .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.code} - ${a.name}')))
                    .toList(),
                onChanged: (value) => creditAccountId = value,
              ),
              TextField(
                controller: refController,
                decoration: const InputDecoration(labelText: 'Reference (Optional)'),
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
              if (debitAccountId != null && creditAccountId != null) {
                final confirmed = await PasswordConfirmationDialog.show(context);
                if (!confirmed || !mounted) return;

                await provider.createJournalEntry(
                  description: descController.text,
                  amount: double.tryParse(amountController.text) ?? 0,
                  debitAccountId: debitAccountId!,
                  creditAccountId: creditAccountId!,
                  reference: refController.text,
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class BankReconciliationScreen extends StatefulWidget {
  const BankReconciliationScreen({super.key});

  @override
  State<BankReconciliationScreen> createState() => _BankReconciliationScreenState();
}

class _BankReconciliationScreenState extends State<BankReconciliationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountingProvider>().loadReconciliations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Reconciliation'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddReconciliationDialog(context),
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
      drawer: const AppDrawer(currentRoute: '/accounting/bank-reconciliation'),
      body: Consumer<AccountingProvider>(
        builder: (context, provider, _) {
          if (provider.reconciliations.isEmpty) {
            return const Center(child: Text('No reconciliations yet'));
          }

          return ListView.builder(
            itemCount: provider.reconciliations.length,
            itemBuilder: (context, index) {
              final rec = provider.reconciliations[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    rec.isReconciled ? Icons.check_circle : Icons.pending,
                    color: rec.isReconciled ? Colors.green : Colors.orange,
                  ),
                  title: Text('Statement: UGX ${rec.statementBalance.toStringAsFixed(0)}'),
                  subtitle: Text('Book: UGX ${rec.bookBalance.toStringAsFixed(0)}'),
                  trailing: rec.isReconciled
                      ? const Text('Reconciled', style: TextStyle(color: Colors.green))
                      : TextButton(
                          onPressed: () async {
                            final confirmed = await PasswordConfirmationDialog.show(context);
                            if (!confirmed || !mounted) return;
                            provider.reconcileAccount(rec.id!);
                          },
                          child: const Text('Reconcile'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddReconciliationDialog(BuildContext context) {
    final provider = context.read<AccountingProvider>();
    final statementController = TextEditingController();
    final bookController = TextEditingController();
    final adjustedController = TextEditingController();
    int? bankAccountId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('New Reconciliation'),
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
                initialValue: bankAccountId,
                decoration: const InputDecoration(labelText: 'Bank Account'),
                items: provider.accounts
                    .where((a) => a.type == 'Asset' && a.subType == 'Current Asset')
                    .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.code} - ${a.name}')))
                    .toList(),
                onChanged: (value) => bankAccountId = value,
              ),
              TextField(
                controller: statementController,
                decoration: const InputDecoration(labelText: 'Statement Balance'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: bookController,
                decoration: const InputDecoration(labelText: 'Book Balance'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: adjustedController,
                decoration: const InputDecoration(labelText: 'Adjusted Balance'),
                keyboardType: TextInputType.number,
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
              if (bankAccountId != null) {
                final confirmed = await PasswordConfirmationDialog.show(context);
                if (!confirmed || !mounted) return;

                await provider.createBankReconciliation(BankReconciliation(
                  bankAccountId: bankAccountId!,
                  statementBalance: double.tryParse(statementController.text) ?? 0,
                  bookBalance: double.tryParse(bookController.text) ?? 0,
                  adjustedBalance: double.tryParse(adjustedController.text) ?? 0,
                ));
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class PettyCashScreen extends StatefulWidget {
  const PettyCashScreen({super.key});

  @override
  State<PettyCashScreen> createState() => _PettyCashScreenState();
}

class _PettyCashScreenState extends State<PettyCashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountingProvider>().loadPettyCashTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Petty Cash'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTransactionDialog(context),
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
      drawer: const AppDrawer(currentRoute: '/accounting/petty-cash'),
      body: Consumer<AccountingProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Balance:', style: TextStyle(fontSize: 18)),
                      Text(
                        'UGX ${provider.pettyCashBalance.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: provider.pettyCashBalance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.pettyCashTransactions.length,
                  itemBuilder: (context, index) {
                    final txn = provider.pettyCashTransactions[index];
                    return ListTile(
                      leading: Icon(
                        txn.type == 'In' ? Icons.arrow_downward : Icons.arrow_upward,
                        color: txn.type == 'In' ? Colors.green : Colors.red,
                      ),
                      title: Text(txn.description),
                      subtitle: Text(txn.transactionDate.toString().split(' ')[0]),
                      trailing: Text(
                        '${txn.type == 'In' ? '+' : '-'}UGX ${txn.amount.asDouble.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: txn.type == 'In' ? Colors.green : Colors.red,
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

  void _showAddTransactionDialog(BuildContext context) {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final paidToController = TextEditingController();
    String type = 'Out';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Add Transaction'),
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
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['In', 'Out']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (value) => type = value!,
              ),
              if (type == 'Out')
                TextField(
                  controller: paidToController,
                  decoration: const InputDecoration(labelText: 'Paid To'),
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

              await accountingProvider.addPettyCashTransaction(
                description: descController.text,
                amount: double.tryParse(amountController.text) ?? 0,
                type: type,
                paidTo: paidToController.text.isNotEmpty ? paidToController.text : null,
              );
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

class TrialBalanceScreen extends StatefulWidget {
  const TrialBalanceScreen({super.key});

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
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
        title: const Text('Trial Balance'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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
      drawer: const AppDrawer(currentRoute: '/accounting/trial-balance'),
      body: Consumer<AccountingProvider>(
        builder: (context, provider, _) {
          final trialBalance = provider.generateTrialBalance();
          final entries = trialBalance['entries'] as List<Map<String, dynamic>>;
          final totalDebits = trialBalance['totalDebits'] as double;
          final totalCredits = trialBalance['totalCredits'] as double;
          final isBalanced = trialBalance['isBalanced'] as bool;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: isBalanced ? Colors.green.shade100 : Colors.red.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isBalanced ? Icons.check_circle : Icons.warning,
                        color: isBalanced ? Colors.green : Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      isBalanced ? 'Books are Balanced' : 'Books are NOT Balanced',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isBalanced ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final account = entry['account'] as Account;
                    return ListTile(
                      title: Text('${account.code} - ${account.name}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              entry['debit'] > 0 ? 'UGX ${entry['debit'].toStringAsFixed(0)}' : '',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              entry['credit'] > 0 ? 'UGX ${entry['credit'].toStringAsFixed(0)}' : '',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(width: 100, child: Text('Total Debits:')),
                    SizedBox(
                      width: 100,
                      child: Text(
                        'UGX ${totalDebits.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        'UGX ${totalCredits.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
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
        title: const Text('Profit & Loss'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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
      drawer: const AppDrawer(currentRoute: '/accounting/profit-loss'),
      body: Consumer<AccountingProvider>(
        builder: (context, provider, _) {
          final pnl = provider.generateProfitAndLoss();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Revenue', pnl['revenue'] as double, Colors.green),
                const SizedBox(height: 16),
                _buildSection('Expenses', pnl['expenses'] as double, Colors.red),
                const Divider(height: 32),
                _buildSection('Net Income', pnl['netIncome'] as double,
                    (pnl['netIncome'] as double) >= 0 ? Colors.green : Colors.red),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(
          'UGX ${amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
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
        title: const Text('Balance Sheet'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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
      drawer: const AppDrawer(currentRoute: '/accounting/balance-sheet'),
      body: Consumer<AccountingProvider>(
        builder: (context, provider, _) {
          final bs = provider.generateBalanceSheet();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Total Assets', bs['assets'] as double, Colors.blue),
                const SizedBox(height: 16),
                _buildSection('Total Liabilities', bs['liabilities'] as double, Colors.red),
                const SizedBox(height: 16),
                _buildSection('Total Equity', bs['equity'] as double, Colors.purple),
                const Divider(height: 32),
                _buildSection(
                  'Liabilities + Equity',
                  (bs['liabilities'] as double) + (bs['equity'] as double),
                  Colors.orange,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(
          'UGX ${amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
