import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/database_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Expense> get recentExpenses =>
      _expenses.take(20).toList();

  List<Expense> filteredExpenses({DateTime? startDate, DateTime? endDate, String? category}) {
    var result = _expenses;
    if (startDate != null) {
      result = result.where((e) => e.expenseDate.isAfter(startDate) || e.expenseDate.isAtSameMomentAs(startDate)).toList();
    }
    if (endDate != null) {
      result = result.where((e) => e.expenseDate.isBefore(endDate) || e.expenseDate.isAtSameMomentAs(endDate)).toList();
    }
    if (category != null && category.isNotEmpty) {
      result = result.where((e) => e.category == category).toList();
    }
    return result;
  }

  double getTotalExpenses({DateTime? startDate, DateTime? endDate}) {
    final filtered = filteredExpenses(startDate: startDate, endDate: endDate);
    return filtered.fold(0, (sum, e) => sum + e.amount.asDouble);
  }

  Map<String, double> getExpensesByCategory({DateTime? startDate, DateTime? endDate}) {
    final filtered = filteredExpenses(startDate: startDate, endDate: endDate);
    final Map<String, double> result = {};
    for (final expense in filtered) {
      result[expense.category] = (result[expense.category] ?? 0) + expense.amount.asDouble;
    }
    return result;
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final maps = await Future.microtask(() async {
        return await _db.query('expenses', where: 'is_deleted = 0', orderBy: 'expense_date DESC');
      });
      _expenses = maps.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load expenses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureLoaded() async {
    if (_expenses.isEmpty && !_isLoading) {
      await loadExpenses();
    }
  }

  Future<bool> createExpense(Expense expense) async {
    try {
      final id = await _db.insert('expenses', expense.toMap());
      final newExpense = Expense(
        id: id,
        category: expense.category,
        description: expense.description,
        amount: expense.amount,
        expenseDate: expense.expenseDate,
        paymentMethod: expense.paymentMethod,
        reference: expense.reference,
        receiptPath: expense.receiptPath,
        notes: expense.notes,
        createdAt: expense.createdAt,
        updatedAt: expense.updatedAt,
      );
      _expenses.insert(0, newExpense);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create expense: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(Expense expense) async {
    try {
      final updated = Expense(
        id: expense.id,
        category: expense.category,
        description: expense.description,
        amount: expense.amount,
        expenseDate: expense.expenseDate,
        paymentMethod: expense.paymentMethod,
        reference: expense.reference,
        receiptPath: expense.receiptPath,
        notes: expense.notes,
        createdAt: expense.createdAt,
        updatedAt: DateTime.now(),
      );
      await _db.update('expenses', updated.toMap(), id: expense.id!);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update expense: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int expenseId) async {
    try {
      await _db.delete('expenses', id: expenseId);
      _expenses.removeWhere((e) => e.id == expenseId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete expense: $e';
      notifyListeners();
      return false;
    }
  }

  Expense? getExpenseById(int id) {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<String> get defaultCategories =>
      ['Utilities', 'Transport', 'Salaries', 'Supplies', 'Rent', 'Maintenance', 'Other'];
}
