import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../utils/money.dart';
import '../services/database_service.dart';

class AccountingProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Account> _accounts = [];
  List<JournalEntry> _journalEntries = [];
  List<BankReconciliation> _reconciliations = [];
  List<PettyCashTransaction> _pettyCashTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _nextEntryNumber = 1;

  List<Account> get accounts => _accounts;
  List<JournalEntry> get journalEntries => _journalEntries;
  List<BankReconciliation> get reconciliations => _reconciliations;
  List<PettyCashTransaction> get pettyCashTransactions => _pettyCashTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Account> get assetAccounts => _accounts.where((a) => a.type == 'Asset').toList();
  List<Account> get liabilityAccounts => _accounts.where((a) => a.type == 'Liability').toList();
  List<Account> get equityAccounts => _accounts.where((a) => a.type == 'Equity').toList();
  List<Account> get revenueAccounts => _accounts.where((a) => a.type == 'Revenue').toList();
  List<Account> get expenseAccounts => _accounts.where((a) => a.type == 'Expense').toList();

  double get totalAssets => assetAccounts.fold(0, (sum, a) => sum + a.balance.asDouble);
  double get totalLiabilities => liabilityAccounts.fold(0, (sum, a) => sum + a.balance.asDouble);
  double get totalEquity => equityAccounts.fold(0, (sum, a) => sum + a.balance.asDouble);
  double get totalRevenue => revenueAccounts.fold(0, (sum, a) => sum + a.balance.asDouble);
  double get totalExpenses => expenseAccounts.fold(0, (sum, a) => sum + a.balance.asDouble);
  double get netIncome => totalRevenue - totalExpenses;

  double get pettyCashBalance {
    double balance = 0;
    for (final t in _pettyCashTransactions) {
      if (t.type == 'In') {
        balance += t.amount.asDouble;
      } else {
        balance -= t.amount.asDouble;
      }
    }
    return balance;
  }

  Future<void> loadAccounts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final maps = await Future.microtask(() async {
        return await _db.query('accounts', orderBy: 'code');
      });
      _accounts = maps.map((map) => Account.fromMap(map)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load accounts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadJournalEntries() async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('journal_entries', orderBy: 'entry_date DESC');
      });
      _journalEntries = maps.map((map) => JournalEntry.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load journal entries: $e';
      notifyListeners();
    }
  }

  Future<void> loadReconciliations() async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('bank_reconciliations', orderBy: 'statement_date DESC');
      });
      _reconciliations = maps.map((map) => BankReconciliation.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load reconciliations: $e';
      notifyListeners();
    }
  }

  Future<void> loadPettyCashTransactions() async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('petty_cash_transactions', orderBy: 'transaction_date DESC');
      });
      _pettyCashTransactions = maps.map((map) => PettyCashTransaction.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load petty cash transactions: $e';
      notifyListeners();
    }
  }

  Future<bool> createAccount(Account account) async {
    try {
      final id = await _db.insert('accounts', account.toMap());
      final newAccount = Account(
        id: id,
        code: account.code,
        name: account.name,
        type: account.type,
        subType: account.subType,
        balance: account.balance,
        parentId: account.parentId,
        isActive: account.isActive,
        description: account.description,
        createdAt: account.createdAt,
        updatedAt: account.updatedAt,
      );
      _accounts.add(newAccount);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create account: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAccount(Account account) async {
    try {
      await _db.update('accounts', account.toMap(), id: account.id!);
      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _accounts[index] = account;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update account: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount(int accountId) async {
    try {
      await _db.delete('accounts', id: accountId);
      _accounts.removeWhere((a) => a.id == accountId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete account: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createJournalEntry({
    required String description,
    required double amount,
    required int debitAccountId,
    required int creditAccountId,
    String? reference,
    String? notes,
    int? userId,
  }) async {
    try {
      final entryNumber = 'JE${_nextEntryNumber.toString().padLeft(5, '0')}';
      _nextEntryNumber++;

      final moneyAmount = Money.fromDouble(amount);
      final id = await _db.insert('journal_entries', {
        'entry_number': entryNumber,
        'entry_date': DateTime.now().toIso8601String(),
        'description': description,
        'amount': moneyAmount.asDouble,
        'debit_account_id': debitAccountId,
        'credit_account_id': creditAccountId,
        'reference': reference,
        'notes': notes,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      _journalEntries.insert(0, JournalEntry(
        id: id,
        entryNumber: entryNumber,
        entryDate: DateTime.now(),
        description: description,
        amount: moneyAmount,
        debitAccountId: debitAccountId,
        creditAccountId: creditAccountId,
        reference: reference,
        notes: notes,
        userId: userId,
      ));

      final debitIndex = _accounts.indexWhere((a) => a.id == debitAccountId);
      if (debitIndex != -1) {
        final debitAccount = _accounts[debitIndex];
        final balanceChange = (debitAccount.type == 'Asset' || debitAccount.type == 'Expense') ? moneyAmount : -moneyAmount;
        _accounts[debitIndex] = debitAccount.copyWith(
          balance: debitAccount.balance + balanceChange,
        );
        await _db.update('accounts', _accounts[debitIndex].toMap(), id: debitAccountId);
      }

      final creditIndex = _accounts.indexWhere((a) => a.id == creditAccountId);
      if (creditIndex != -1) {
        final creditAccount = _accounts[creditIndex];
        final balanceChange = (creditAccount.type == 'Liability' || creditAccount.type == 'Equity' || creditAccount.type == 'Revenue') ? moneyAmount : -moneyAmount;
        _accounts[creditIndex] = creditAccount.copyWith(
          balance: creditAccount.balance + balanceChange,
        );
        await _db.update('accounts', _accounts[creditIndex].toMap(), id: creditAccountId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create journal entry: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createBankReconciliation(BankReconciliation reconciliation) async {
    try {
      final id = await _db.insert('bank_reconciliations', reconciliation.toMap());
      final newReconciliation = BankReconciliation(
        id: id,
        bankAccountId: reconciliation.bankAccountId,
        statementDate: reconciliation.statementDate,
        statementBalance: reconciliation.statementBalance,
        bookBalance: reconciliation.bookBalance,
        adjustedBalance: reconciliation.adjustedBalance,
        isReconciled: reconciliation.isReconciled,
        reconciledAt: reconciliation.reconciledAt,
        notes: reconciliation.notes,
        createdAt: reconciliation.createdAt,
      );
      _reconciliations.insert(0, newReconciliation);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create reconciliation: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> reconcileAccount(int reconciliationId) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _db.update('bank_reconciliations', {
        'is_reconciled': 1,
        'reconciled_at': now,
      }, id: reconciliationId);

      final index = _reconciliations.indexWhere((r) => r.id == reconciliationId);
      if (index != -1) {
        _reconciliations[index] = BankReconciliation(
          id: _reconciliations[index].id,
          bankAccountId: _reconciliations[index].bankAccountId,
          statementDate: _reconciliations[index].statementDate,
          statementBalance: _reconciliations[index].statementBalance,
          bookBalance: _reconciliations[index].bookBalance,
          adjustedBalance: _reconciliations[index].adjustedBalance,
          isReconciled: true,
          reconciledAt: DateTime.now(),
          notes: _reconciliations[index].notes,
          createdAt: _reconciliations[index].createdAt,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reconcile: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addPettyCashTransaction({
    required String description,
    required double amount,
    required String type,
    String? paidTo,
    String? receivedFrom,
    String? receiptNumber,
    int? userId,
  }) async {
    try {
      final id = await _db.insert('petty_cash_transactions', {
        'transaction_date': DateTime.now().toIso8601String(),
        'description': description,
        'amount': amount,
        'type': type,
        'paid_to': paidTo,
        'received_from': receivedFrom,
        'receipt_number': receiptNumber,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      _pettyCashTransactions.insert(0, PettyCashTransaction(
        id: id,
        transactionDate: DateTime.now(),
        description: description,
        amount: Money.fromDouble(amount),
        type: type,
        paidTo: paidTo,
        receivedFrom: receivedFrom,
        receiptNumber: receiptNumber,
        userId: userId,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add petty cash transaction: $e';
      notifyListeners();
      return false;
    }
  }

  Account? getAccountById(int id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> generateTrialBalance() {
    final List<Map<String, dynamic>> trialBalance = [];
    double totalDebits = 0;
    double totalCredits = 0;

    for (final account in _accounts.where((a) => a.isActive)) {
      double debit = 0;
      double credit = 0;

      if (account.type == 'Asset' || account.type == 'Expense') {
        if (account.balance.compareTo(Money.zero) >= 0) {
          debit = account.balance.asDouble;
        } else {
          credit = account.balance.asDouble.abs();
        }
      } else {
        if (account.balance.compareTo(Money.zero) >= 0) {
          credit = account.balance.asDouble;
        } else {
          debit = account.balance.asDouble.abs();
        }
      }

      trialBalance.add({
        'account': account,
        'debit': debit,
        'credit': credit,
      });

      totalDebits += debit;
      totalCredits += credit;
    }

    return {
      'entries': trialBalance,
      'totalDebits': totalDebits,
      'totalCredits': totalCredits,
      'isBalanced': (totalDebits - totalCredits).abs() < 0.01,
    };
  }

  Map<String, dynamic> generateProfitAndLoss() {
    return {
      'revenue': totalRevenue,
      'expenses': totalExpenses,
      'netIncome': netIncome,
      'revenueAccounts': revenueAccounts,
      'expenseAccounts': expenseAccounts,
    };
  }

  Map<String, dynamic> generateBalanceSheet() {
    return {
      'assets': totalAssets,
      'liabilities': totalLiabilities,
      'equity': totalEquity,
      'assetAccounts': assetAccounts,
      'liabilityAccounts': liabilityAccounts,
      'equityAccounts': equityAccounts,
    };
  }
}
