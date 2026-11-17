import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../mixins/route_aware_mixin.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense.dart';
import '../../utils/money.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/data_table_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/password_confirmation_dialog.dart';
import '../../config/app_theme.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> with SingleTickerProviderStateMixin, RouteAwareMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().ensureLoaded();
    });
  }

  @override
  void onScreenVisible() {
    context.read<ExpenseProvider>().ensureLoaded();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final expenses = _filterExpenses(expenseProvider.expenses);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Expenses'),
      drawer: const AppDrawer(currentRoute: '/finances'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _searchController,
                        label: 'Search expenses',
                        hint: 'Description or category',
                        prefixIcon: CupertinoIcons.search,
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('All Categories')),
                          ...ExpenseProvider.defaultCategories.map(
                            (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                          ),
                        ],
                        onChanged: (value) => setState(() => _selectedCategory = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, isStart: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.calendar_today, size: 18),
                              const SizedBox(width: 8),
                              Text(_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Start Date'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, isStart: false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.calendar_today, size: 18),
                              const SizedBox(width: 8),
                              Text(_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'End Date'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _selectedCategory = 'All';
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      icon: const AppIcon(icon: CupertinoIcons.clear, size: 18),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${expenses.length} expenses',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                Text(
                  'Total: ${AppTheme.formatCurrency(expenseProvider.getTotalExpenses(startDate: _startDate, endDate: _endDate))}',
                  style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: expenseProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : expenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(icon: CupertinoIcons.money_dollar, size: 64, color: Colors.grey[400], fallbackText: '💵'),
                            const SizedBox(height: 16),
                            Text('No expenses found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                      )
                    : DataTableWidget(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Description')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Payment')),
                          DataColumn(label: Text('Reference')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: expenses
                            .map(
                              (expense) => DataRow(
                                cells: [
                                  DataCell(Text(DateFormat('dd/MM/yyyy').format(expense.expenseDate))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(expense.category),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        expense.category,
                                        style: TextStyle(fontSize: 11, color: _getCategoryTextColor(expense.category), fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Expanded(
                                      child: Text(
                                        expense.description ?? '-',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      AppTheme.formatMoney(expense.amount),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataCell(Text(expense.paymentMethod ?? '-')),
                                  DataCell(Text(expense.reference ?? '-')),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const AppIcon(icon: CupertinoIcons.pencil, size: 18, color: Colors.blue),
                                          tooltip: 'Edit',
                                          onPressed: () => _editExpense(context, expense),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        IconButton(
                                          icon: const AppIcon(icon: CupertinoIcons.delete, size: 18, color: Colors.red),
                                          tooltip: 'Delete',
                                          onPressed: () => _deleteExpense(context, expense),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExpense(context),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const AppIcon(icon: CupertinoIcons.add, size: 20),
        label: const Text('Add Expense'),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Utilities':
        return Colors.blue.withValues(alpha: 0.1);
      case 'Transport':
        return Colors.green.withValues(alpha: 0.1);
      case 'Salaries':
        return Colors.purple.withValues(alpha: 0.1);
      case 'Supplies':
        return Colors.orange.withValues(alpha: 0.1);
      case 'Rent':
        return Colors.red.withValues(alpha: 0.1);
      case 'Maintenance':
        return Colors.teal.withValues(alpha: 0.1);
      default:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }

  Color _getCategoryTextColor(String category) {
    switch (category) {
      case 'Utilities':
        return Colors.blue;
      case 'Transport':
        return Colors.green;
      case 'Salaries':
        return Colors.purple;
      case 'Supplies':
        return Colors.orange;
      case 'Rent':
        return Colors.red;
      case 'Maintenance':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  List<Expense> _filterExpenses(List<Expense> expenses) {
    var result = expenses;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((e) {
        return (e.description?.toLowerCase().contains(query) ?? false) ||
            e.category.toLowerCase().contains(query);
      }).toList();
    }
    if (_selectedCategory != 'All') {
      result = result.where((e) => e.category == _selectedCategory).toList();
    }
    if (_startDate != null) {
      result = result.where((e) {
        return e.expenseDate.isAfter(_startDate!) || e.expenseDate.isAtSameMomentAs(_startDate!);
      }).toList();
    }
    if (_endDate != null) {
      result = result.where((e) {
        return e.expenseDate.isBefore(_endDate!) || e.expenseDate.isAtSameMomentAs(_endDate!);
      }).toList();
    }
    return result;
  }

  void _addExpense(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ExpenseFormDialog(),
    );
  }

  void _editExpense(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => _ExpenseFormDialog(expense: expense),
    );
  }

  void _deleteExpense(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete this expense?\n${AppTheme.formatMoney(expense.amount)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final expenseProvider = context.read<ExpenseProvider>();
              final confirmed = await PasswordConfirmationDialog.show(context);
              if (!confirmed || !context.mounted) return;

              Navigator.pop(context);
              final success = await expenseProvider.deleteExpense(expense.id!);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }
}

class _ExpenseFormDialog extends StatefulWidget {
  final Expense? expense;

  const _ExpenseFormDialog({this.expense});

  @override
  State<_ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<_ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = 'Supplies';
  String _paymentMethod = 'Cash';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _populateFields(widget.expense!);
    }
  }

  void _populateFields(Expense expense) {
    _category = expense.category;
    _descriptionController.text = expense.description ?? '';
    _amountController.text = expense.amount.asDouble.toStringAsFixed(0);
    _paymentMethod = expense.paymentMethod ?? 'Cash';
    _referenceController.text = expense.reference ?? '';
    _notesController.text = expense.notes ?? '';
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await PasswordConfirmationDialog.show(context);
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final expense = Expense(
        id: widget.expense?.id,
        category: _category,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        amount: Money.fromDouble(double.parse(_amountController.text.trim())),
        expenseDate: widget.expense?.expenseDate ?? DateTime.now(),
        paymentMethod: _paymentMethod,
        reference: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = widget.expense == null
          ? await context.read<ExpenseProvider>().createExpense(expense)
          : await context.read<ExpenseProvider>().updateExpense(expense);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.expense == null ? 'Expense added successfully!' : 'Expense updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(),
                        ),
                  items: ExpenseProvider.defaultCategories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) => setState(() => _category = value!),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'What was this expense for?',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _amountController,
                        label: 'Amount (UGX) *',
                        hint: '0',
                        keyboardType: TextInputType.number,
                        prefixText: 'UGX ',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Enter amount';
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) return 'Enter valid amount';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                          DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                          DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                        ],
                        onChanged: (value) => setState(() => _paymentMethod = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _referenceController,
                  label: 'Reference',
                  hint: 'Receipt or transaction number',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _notesController,
                  label: 'Notes',
                  hint: 'Additional information',
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveExpense,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
