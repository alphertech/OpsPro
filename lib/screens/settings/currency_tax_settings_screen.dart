import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/audit.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';

class CurrencyTaxSettingsScreen extends StatefulWidget {
  const CurrencyTaxSettingsScreen({super.key});

  @override
  State<CurrencyTaxSettingsScreen> createState() => _CurrencyTaxSettingsScreenState();
}

class _CurrencyTaxSettingsScreenState extends State<CurrencyTaxSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CurrencyTaxProvider>();
      provider.loadCurrencies();
      provider.loadTaxRates();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Currency & Tax Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(text: 'Currencies'),
            Tab(text: 'Tax Rates'),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerRight,
            child: const Text(
              'Plexus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/settings/currency-tax'),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrenciesTab(),
          _buildTaxRatesTab(),
        ],
      ),
    );
  }

  Widget _buildCurrenciesTab() {
    return Consumer<CurrencyTaxProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Currencies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => _showCurrencyDialog(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.currencies.isEmpty
                  ? const Center(child: Text('No currencies. Tap "Add" to create one.'))
                  : ListView.builder(
                      itemCount: provider.currencies.length,
                      itemBuilder: (context, index) {
                        final currency = provider.currencies[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: currency.isDefault ? Colors.green : Colors.grey,
                            child: Text(
                              currency.symbol,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          title: Text('${currency.code} - ${currency.name}'),
                          subtitle: Text(
                            'Rate: ${currency.exchangeRate}'
                            '${currency.isDefault ? "  •  Default" : ""}'
                            '${!currency.isActive ? "  •  Inactive" : ""}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!currency.isDefault)
                                TextButton(
                                  onPressed: () async {
                                    final confirmed = await PasswordConfirmationDialog.show(context);
                                    if (!confirmed || !mounted) return;
                                    await provider.setDefaultCurrency(currency.id!);
                                  },
                                  child: const Text('Set Default'),
                                )
                              else
                                const Chip(label: Text('Default')),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Edit',
                                onPressed: () => _showCurrencyDialog(context, currency),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDeleteCurrency(context, currency),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaxRatesTab() {
    return Consumer<CurrencyTaxProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax Rates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => _showTaxRateDialog(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.taxRates.isEmpty
                  ? const Center(child: Text('No tax rates. Tap "Add" to create one.'))
                  : ListView.builder(
                      itemCount: provider.taxRates.length,
                      itemBuilder: (context, index) {
                        final taxRate = provider.taxRates[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: taxRate.isDefault ? Colors.green : Colors.grey,
                            child: Text(
                              '${taxRate.rate}%',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          title: Text(taxRate.name),
                          subtitle: Text(
                            '${taxRate.description ?? ""}'
                            '${taxRate.isDefault ? "${(taxRate.description ?? "").isEmpty ? "" : "  •  " }Default" : ""}'
                            '${!taxRate.isActive ? "  •  Inactive" : ""}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!taxRate.isDefault)
                                TextButton(
                                  onPressed: () async {
                                    final confirmed = await PasswordConfirmationDialog.show(context);
                                    if (!confirmed || !mounted) return;
                                    await provider.setDefaultTaxRate(taxRate.id!);
                                  },
                                  child: const Text('Set Default'),
                                )
                              else
                                const Chip(label: Text('Default')),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Edit',
                                onPressed: () => _showTaxRateDialog(context, taxRate),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDeleteTaxRate(context, taxRate),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showCurrencyDialog(BuildContext context, Currency? existing) {
    final isEdit = existing != null;
    final codeController = TextEditingController(text: existing?.code ?? '');
    final nameController = TextEditingController(text: existing?.name ?? '');
    final symbolController = TextEditingController(text: existing?.symbol ?? '');
    final rateController = TextEditingController(text: (existing?.exchangeRate ?? 1).toString());
    bool isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEdit ? 'Edit Currency' : 'Add Currency'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(dialogContext),
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
                  decoration: const InputDecoration(labelText: 'Code (e.g., USD)'),
                  textCapitalization: TextCapitalization.characters,
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: symbolController,
                  decoration: const InputDecoration(labelText: 'Symbol'),
                ),
                TextField(
                  controller: rateController,
                  decoration: const InputDecoration(
                    labelText: 'Exchange Rate (relative to default currency)',
                    helperText: 'e.g. 1 if this is the default, or how many of this = 1 default',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text('Inactive currencies will not appear in selection lists'),
                  value: isActive,
                  onChanged: (v) => setLocalState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Code and Name are required')),
                  );
                  return;
                }
                final rate = double.tryParse(rateController.text);
                if (rate == null || rate <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Exchange rate must be a positive number')),
                  );
                  return;
                }

                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(dialogContext);
                final provider = context.read<CurrencyTaxProvider>();
                final existingCurrency = existing;
                final confirmed = await PasswordConfirmationDialog.show(dialogContext);
                if (!confirmed) return;

                final success = isEdit
                    ? await provider.updateCurrency(Currency(
                        id: existingCurrency!.id!,
                        code: codeController.text.trim(),
                        name: nameController.text.trim(),
                        symbol: symbolController.text.trim(),
                        exchangeRate: rate,
                        isDefault: existingCurrency.isDefault,
                        isActive: isActive,
                        updatedAt: DateTime.now(),
                      ))
                    : await provider.addCurrency(Currency(
                        code: codeController.text.trim(),
                        name: nameController.text.trim(),
                        symbol: symbolController.text.trim(),
                        exchangeRate: rate,
                        isDefault: false,
                        isActive: isActive,
                        updatedAt: DateTime.now(),
                      ));

                if (!success) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(provider.errorMessage ?? 'Failed to save currency')),
                  );
                  return;
                }
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text(isEdit ? 'Currency updated' : 'Currency added')),
                );
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaxRateDialog(BuildContext context, TaxRate? existing) {
    final isEdit = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final rateController = TextEditingController(text: (existing?.rate ?? 0).toString());
    final descController = TextEditingController(text: existing?.description ?? '');
    bool isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEdit ? 'Edit Tax Rate' : 'Add Tax Rate'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(dialogContext),
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
                  decoration: const InputDecoration(labelText: 'Name (e.g. VAT, WHT)'),
                ),
                TextField(
                  controller: rateController,
                  decoration: const InputDecoration(
                    labelText: 'Rate (%)',
                    helperText: 'Enter percentage, e.g. 18 for 18%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text('Inactive tax rates will not appear in selection lists'),
                  value: isActive,
                  onChanged: (v) => setLocalState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }
                final rate = double.tryParse(rateController.text);
                if (rate == null || rate < 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Rate must be a non-negative number')),
                  );
                  return;
                }

                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(dialogContext);
                final provider = context.read<CurrencyTaxProvider>();
                final existingTaxRate = existing;
                final confirmed = await PasswordConfirmationDialog.show(dialogContext);
                if (!confirmed) return;

                final success = isEdit
                    ? await provider.updateTaxRate(TaxRate(
                        id: existingTaxRate!.id!,
                        name: nameController.text.trim(),
                        rate: rate,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        isDefault: existingTaxRate.isDefault,
                        isActive: isActive,
                        createdAt: existingTaxRate.createdAt,
                      ))
                    : await provider.addTaxRate(TaxRate(
                        name: nameController.text.trim(),
                        rate: rate,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        isDefault: false,
                        isActive: isActive,
                        createdAt: DateTime.now(),
                      ));

                if (!success) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(provider.errorMessage ?? 'Failed to save tax rate')),
                  );
                  return;
                }
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text(isEdit ? 'Tax rate updated' : 'Tax rate added')),
                );
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCurrency(BuildContext context, Currency currency) async {
    final provider = context.read<CurrencyTaxProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final currencyId = currency.id!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Currency'),
        content: Text(
          'Are you sure you want to delete "${currency.code} - ${currency.name}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (!context.mounted) return;
    final pwdOk = await PasswordConfirmationDialog.show(context);
    if (!pwdOk || !mounted) return;

    final success = await provider.deleteCurrency(currencyId);
    if (!success) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to delete currency')),
      );
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Currency deleted')));
  }

  Future<void> _confirmDeleteTaxRate(BuildContext context, TaxRate taxRate) async {
    final provider = context.read<CurrencyTaxProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final taxRateId = taxRate.id!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Tax Rate'),
        content: Text(
          'Are you sure you want to delete "${taxRate.name}" (${taxRate.rate}%)?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (!context.mounted) return;
    final pwdOk = await PasswordConfirmationDialog.show(context);
    if (!pwdOk || !mounted) return;

    final success = await provider.deleteTaxRate(taxRateId);
    if (!success) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to delete tax rate')),
      );
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Tax rate deleted')));
  }
}
