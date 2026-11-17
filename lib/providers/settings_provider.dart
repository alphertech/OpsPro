import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/audit.dart';
import '../services/database_service.dart';

class CurrencyTaxProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Currency> _currencies = [];
  List<TaxRate> _taxRates = [];
  Currency? _defaultCurrency;
  TaxRate? _defaultTaxRate;
  bool _isLoading = false;
  String? _errorMessage;

  List<Currency> get currencies => _currencies;
  List<TaxRate> get taxRates => _taxRates;
  Currency? get defaultCurrency => _defaultCurrency;
  TaxRate? get defaultTaxRate => _defaultTaxRate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCurrencies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final maps = await Future.microtask(() async {
        return await _db.query('currencies', orderBy: 'code');
      });
      _currencies = maps.map((map) => Currency.fromMap(map)).toList();
      _defaultCurrency = _currencies.firstWhere(
        (c) => c.isDefault,
        orElse: () => _currencies.isNotEmpty ? _currencies.first : Currency(code: 'UGX', name: 'Ugandan Shilling', symbol: 'USh'),
      );
    } catch (e) {
      _errorMessage = 'Failed to load currencies: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTaxRates() async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('tax_rates', orderBy: 'name');
      });
      _taxRates = maps.map((map) => TaxRate.fromMap(map)).toList();
      _defaultTaxRate = _taxRates.firstWhere(
        (t) => t.isDefault,
        orElse: () => _taxRates.isNotEmpty ? _taxRates.first : TaxRate(name: 'No Tax', rate: 0),
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load tax rates: $e';
      notifyListeners();
    }
  }

  Future<bool> addCurrency(Currency currency) async {
    try {
      final id = await _db.insert('currencies', currency.toMap());
      _currencies.add(Currency(
        id: id,
        code: currency.code,
        name: currency.name,
        symbol: currency.symbol,
        exchangeRate: currency.exchangeRate,
        isDefault: currency.isDefault,
        isActive: currency.isActive,
        updatedAt: currency.updatedAt,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add currency: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCurrency(Currency currency) async {
    try {
      await _db.update('currencies', currency.toMap(), id: currency.id!);
      final index = _currencies.indexWhere((c) => c.id == currency.id);
      if (index != -1) {
        _currencies[index] = currency;
      }
      if (currency.isDefault) {
        _defaultCurrency = currency;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update currency: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCurrency(int currencyId) async {
    try {
      await _db.delete('currencies', id: currencyId);
      _currencies.removeWhere((c) => c.id == currencyId);
      if (_defaultCurrency?.id == currencyId) {
        _defaultCurrency = _currencies.isNotEmpty ? _currencies.first : null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete currency: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefaultCurrency(int currencyId) async {
    try {
      for (var currency in _currencies) {
        final updated = Currency(
          id: currency.id,
          code: currency.code,
          name: currency.name,
          symbol: currency.symbol,
          exchangeRate: currency.exchangeRate,
          isDefault: currency.id == currencyId,
          isActive: currency.isActive,
          updatedAt: DateTime.now(),
        );
        await _db.update('currencies', updated.toMap(), id: currency.id!);
        final index = _currencies.indexWhere((c) => c.id == currency.id);
        if (index != -1) {
          _currencies[index] = updated;
        }
      }
      _defaultCurrency = _currencies.firstWhere((c) => c.id == currencyId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to set default currency: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addTaxRate(TaxRate taxRate) async {
    try {
      final id = await _db.insert('tax_rates', taxRate.toMap());
      _taxRates.add(TaxRate(
        id: id,
        name: taxRate.name,
        rate: taxRate.rate,
        description: taxRate.description,
        isDefault: taxRate.isDefault,
        isActive: taxRate.isActive,
        createdAt: taxRate.createdAt,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add tax rate: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTaxRate(TaxRate taxRate) async {
    try {
      await _db.update('tax_rates', taxRate.toMap(), id: taxRate.id!);
      final index = _taxRates.indexWhere((t) => t.id == taxRate.id);
      if (index != -1) {
        _taxRates[index] = taxRate;
      }
      if (taxRate.isDefault) {
        _defaultTaxRate = taxRate;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update tax rate: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTaxRate(int taxRateId) async {
    try {
      await _db.delete('tax_rates', id: taxRateId);
      _taxRates.removeWhere((t) => t.id == taxRateId);
      if (_defaultTaxRate?.id == taxRateId) {
        _defaultTaxRate = _taxRates.isNotEmpty ? _taxRates.first : null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete tax rate: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefaultTaxRate(int taxRateId) async {
    try {
      for (var taxRate in _taxRates) {
        final updated = TaxRate(
          id: taxRate.id,
          name: taxRate.name,
          rate: taxRate.rate,
          description: taxRate.description,
          isDefault: taxRate.id == taxRateId,
          isActive: taxRate.isActive,
          createdAt: taxRate.createdAt,
        );
        await _db.update('tax_rates', updated.toMap(), id: taxRate.id!);
        final index = _taxRates.indexWhere((t) => t.id == taxRate.id);
        if (index != -1) {
          _taxRates[index] = updated;
        }
      }
      _defaultTaxRate = _taxRates.firstWhere((t) => t.id == taxRateId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to set default tax rate: $e';
      notifyListeners();
      return false;
    }
  }

  double convertAmount(double amount, String fromCode, String toCode) {
    if (fromCode == toCode) return amount;

    final fromCurrency = _currencies.firstWhere(
      (c) => c.code == fromCode,
      orElse: () => Currency(code: fromCode, name: fromCode, symbol: fromCode),
    );
    final toCurrency = _currencies.firstWhere(
      (c) => c.code == toCode,
      orElse: () => Currency(code: toCode, name: toCode, symbol: toCode),
    );

    final amountInDefault = amount / fromCurrency.exchangeRate;
    return amountInDefault * toCurrency.exchangeRate;
  }
}

class AuditProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<AuditLog> _auditLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AuditLog> get auditLogs => _auditLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAuditLogs({String? tableName, int? limit}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? where;
      List<dynamic>? whereArgs;
      if (tableName != null) {
        where = 'table_name = ?';
        whereArgs = [tableName];
      }

      final maps = await Future.microtask(() async {
        return await _db.query(
          'audit_logs',
          where: where,
          whereArgs: whereArgs,
          orderBy: 'created_at DESC',
          limit: limit ?? 100,
        );
      });
      _auditLogs = maps.map((map) => AuditLog.fromMap(map)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load audit logs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logAction({
    required String tableName,
    int? recordId,
    required String action,
    String? oldValues,
    String? newValues,
    int? userId,
    String? userName,
  }) async {
    try {
      await _db.insert('audit_logs', {
        'table_name': tableName,
        'record_id': recordId,
        'action': action,
        'old_values': oldValues,
        'new_values': newValues,
        'user_id': userId,
        'user_name': userName,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  List<AuditLog> getLogsForTable(String tableName) {
    return _auditLogs.where((log) => log.tableName == tableName).toList();
  }

  List<AuditLog> getLogsForRecord(String tableName, int recordId) {
    return _auditLogs.where((log) => log.tableName == tableName && log.recordId == recordId).toList();
  }
}

class RecurringInvoiceProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<RecurringInvoice> _recurringInvoices = [];
  List<CreditMemo> _creditMemos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RecurringInvoice> get recurringInvoices => _recurringInvoices;
  List<CreditMemo> get creditMemos => _creditMemos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<RecurringInvoice> get activeRecurring => _recurringInvoices.where((r) => r.status == 'Active').toList();
  List<RecurringInvoice> get dueRecurring => _recurringInvoices.where((r) => r.status == 'Active' && r.nextDue.isBefore(DateTime.now())).toList();

  Future<void> loadRecurringInvoices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final maps = await Future.microtask(() async {
        return await _db.query('recurring_invoices', orderBy: 'next_due');
      });
      _recurringInvoices = maps.map((map) => RecurringInvoice.fromMap(map)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load recurring invoices: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCreditMemos() async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('credit_memos', orderBy: 'memo_date DESC');
      });
      _creditMemos = maps.map((map) => CreditMemo.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load credit memos: $e';
      notifyListeners();
    }
  }

  Future<bool> createRecurringInvoice(RecurringInvoice invoice) async {
    try {
      final id = await _db.insert('recurring_invoices', invoice.toMap());
      _recurringInvoices.add(RecurringInvoice(
        id: id,
        name: invoice.name,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        frequency: invoice.frequency,
        startDate: invoice.startDate,
        endDate: invoice.endDate,
        lastGenerated: invoice.lastGenerated,
        nextDue: invoice.nextDue,
        amount: invoice.amount,
        taxAmount: invoice.taxAmount,
        totalAmount: invoice.totalAmount,
        notes: invoice.notes,
        status: invoice.status,
        createdAt: invoice.createdAt,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create recurring invoice: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecurringInvoice(RecurringInvoice invoice) async {
    try {
      await _db.update('recurring_invoices', invoice.toMap(), id: invoice.id!);
      final index = _recurringInvoices.indexWhere((r) => r.id == invoice.id);
      if (index != -1) {
        _recurringInvoices[index] = invoice;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update recurring invoice: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createCreditMemo(CreditMemo memo) async {
    try {
      final id = await _db.insert('credit_memos', memo.toMap());
      _creditMemos.insert(0, CreditMemo(
        id: id,
        memoNumber: memo.memoNumber,
        saleId: memo.saleId,
        invoiceNumber: memo.invoiceNumber,
        customerId: memo.customerId,
        customerName: memo.customerName,
        memoDate: memo.memoDate,
        amount: memo.amount,
        taxAmount: memo.taxAmount,
        totalAmount: memo.totalAmount,
        reason: memo.reason,
        status: memo.status,
        createdAt: memo.createdAt,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create credit memo: $e';
      notifyListeners();
      return false;
    }
  }

  DateTime calculateNextDue(DateTime currentDue, String frequency) {
    switch (frequency) {
      case 'Weekly':
        return currentDue.add(const Duration(days: 7));
      case 'Bi-weekly':
        return currentDue.add(const Duration(days: 14));
      case 'Monthly':
        final nextMonth = currentDue.month < 12 ? currentDue.month + 1 : 1;
        final nextYear = currentDue.month < 12 ? currentDue.year : currentDue.year + 1;
        final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final day = currentDue.day > lastDayOfNextMonth ? lastDayOfNextMonth : currentDue.day;
        return DateTime(nextYear, nextMonth, day);
      case 'Quarterly':
        final targetMonth = currentDue.month + 3;
        final qYear = targetMonth > 12 ? currentDue.year + 1 : currentDue.year;
        final qMonth = targetMonth > 12 ? targetMonth - 12 : targetMonth;
        final lastDay = DateTime(qYear, qMonth + 1, 0).day;
        final day = currentDue.day > lastDay ? lastDay : currentDue.day;
        return DateTime(qYear, qMonth, day);
      case 'Yearly':
        final lastDay = DateTime(currentDue.year + 1, currentDue.month + 1, 0).day;
        final day = currentDue.day > lastDay ? lastDay : currentDue.day;
        return DateTime(currentDue.year + 1, currentDue.month, day);
      default:
        final nextMonth = currentDue.month < 12 ? currentDue.month + 1 : 1;
        final nextYear = currentDue.month < 12 ? currentDue.year : currentDue.year + 1;
        final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final day = currentDue.day > lastDayOfNextMonth ? lastDayOfNextMonth : currentDue.day;
        return DateTime(nextYear, nextMonth, day);
    }
  }
}

class WarehouseProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Warehouse> _warehouses = [];
  List<StockTransfer> _stockTransfers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Warehouse> get warehouses => _warehouses;
  List<StockTransfer> get stockTransfers => _stockTransfers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Warehouse? get defaultWarehouse {
    try {
      return _warehouses.firstWhere((w) => w.isDefault);
    } catch (e) {
      return _warehouses.isNotEmpty ? _warehouses.first : null;
    }
  }

  Future<void> loadWarehouses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final maps = await Future.microtask(() async {
        return await _db.query('warehouses', orderBy: 'name');
      });
      _warehouses = maps.map((map) => Warehouse.fromMap(map)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load warehouses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStockTransfers() async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('stock_transfers', orderBy: 'transfer_date DESC');
      });
      _stockTransfers = maps.map((map) => StockTransfer.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load stock transfers: $e';
      notifyListeners();
    }
  }

  Future<bool> createWarehouse(Warehouse warehouse) async {
    try {
      final id = await _db.insert('warehouses', warehouse.toMap());
      _warehouses.add(Warehouse(
        id: id,
        name: warehouse.name,
        code: warehouse.code,
        address: warehouse.address,
        manager: warehouse.manager,
        isDefault: warehouse.isDefault,
        isActive: warehouse.isActive,
        createdAt: warehouse.createdAt,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create warehouse: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWarehouse(Warehouse warehouse) async {
    try {
      await _db.update('warehouses', warehouse.toMap(), id: warehouse.id!);
      final index = _warehouses.indexWhere((w) => w.id == warehouse.id);
      if (index != -1) {
        _warehouses[index] = warehouse;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update warehouse: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createStockTransfer(StockTransfer transfer) async {
    try {
      if (transfer.fromWarehouseId == transfer.toWarehouseId) {
        _errorMessage = 'Source and destination warehouses cannot be the same.';
        notifyListeners();
        return false;
      }

      final fromWarehouse = _warehouses.firstWhere((w) => w.id == transfer.fromWarehouseId, orElse: () => Warehouse(
        id: 0,
        name: '',
        code: '',
        address: '',
        manager: '',
        isDefault: false,
        isActive: false,
        createdAt: DateTime.now(),
      ));
      final toWarehouse = _warehouses.firstWhere((w) => w.id == transfer.toWarehouseId, orElse: () => Warehouse(
        id: 0,
        name: '',
        code: '',
        address: '',
        manager: '',
        isDefault: false,
        isActive: false,
        createdAt: DateTime.now(),
      ));

      if (fromWarehouse.id == 0 || toWarehouse.id == 0) {
        _errorMessage = 'Invalid warehouse selected.';
        notifyListeners();
        return false;
      }

      final id = await _db.insert('stock_transfers', transfer.toMap());
      _stockTransfers.insert(0, StockTransfer(
        id: id,
        transferNumber: transfer.transferNumber,
        fromWarehouseId: transfer.fromWarehouseId,
        toWarehouseId: transfer.toWarehouseId,
        fromWarehouseName: transfer.fromWarehouseName,
        toWarehouseName: transfer.toWarehouseName,
        transferDate: transfer.transferDate,
        status: transfer.status,
        notes: transfer.notes,
        createdBy: transfer.createdBy,
        createdAt: transfer.createdAt,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create stock transfer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeStockTransfer(int transferId) async {
    try {
      await _db.update('stock_transfers', {
        'status': 'Completed',
      }, id: transferId);

      final index = _stockTransfers.indexWhere((t) => t.id == transferId);
      if (index != -1) {
        _stockTransfers[index] = StockTransfer(
          id: _stockTransfers[index].id,
          transferNumber: _stockTransfers[index].transferNumber,
          fromWarehouseId: _stockTransfers[index].fromWarehouseId,
          toWarehouseId: _stockTransfers[index].toWarehouseId,
          fromWarehouseName: _stockTransfers[index].fromWarehouseName,
          toWarehouseName: _stockTransfers[index].toWarehouseName,
          transferDate: _stockTransfers[index].transferDate,
          status: 'Completed',
          notes: _stockTransfers[index].notes,
          createdBy: _stockTransfers[index].createdBy,
          createdAt: _stockTransfers[index].createdAt,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete stock transfer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Map<int, double>> getStockForWarehouse(int warehouseId) async {
    try {
      final maps = await _db.query('warehouses_stock', where: 'warehouse_id = ?', whereArgs: [warehouseId]);
      final Map<int, double> stock = {};
      for (final map in maps) {
        stock[map['product_id'] as int] = (map['quantity'] as num?)?.toDouble() ?? 0.0;
      }
      return stock;
    } catch (e) {
      return {};
    }
  }

  Future<bool> updateWarehouseStock(int warehouseId, int productId, double quantity) async {
    try {
      final existing = await _db.query('warehouses_stock',
          where: 'warehouse_id = ? AND product_id = ?',
          whereArgs: [warehouseId, productId]);

      if (existing.isNotEmpty) {
        await _db.update('warehouses_stock', {
          'quantity': quantity,
        }, id: existing.first['id']);
      } else {
        await _db.insert('warehouses_stock', {
          'warehouse_id': warehouseId,
          'product_id': productId,
          'quantity': quantity,
        });
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update warehouse stock: $e';
      notifyListeners();
      return false;
    }
  }
}

class CommunicationProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<EmailQueue> _emailQueue = [];
  List<InternalMemo> _memos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EmailQueue> get emailQueue => _emailQueue;
  List<InternalMemo> get memos => _memos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<EmailQueue> get pendingEmails => _emailQueue.where((e) => e.status == 'Pending').toList();
  List<InternalMemo> get activeMemos => _memos.where((m) => m.expiresAt == null || m.expiresAt!.isAfter(DateTime.now())).toList();

  Future<void> loadEmailQueue() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final maps = await Future.microtask(() async {
        return await _db.query('email_queue', orderBy: 'created_at DESC');
      });
      _emailQueue = maps.map((map) => EmailQueue.fromMap(map)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load email queue: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMemos() async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('internal_memos', orderBy: 'is_pinned DESC, created_at DESC');
      });
      _memos = maps.map((map) => InternalMemo.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load memos: $e';
      notifyListeners();
    }
  }

  Future<bool> queueEmail({
    required String recipient,
    required String subject,
    required String body,
    String? attachmentPath,
  }) async {
    try {
      final id = await _db.insert('email_queue', {
        'recipient': recipient,
        'subject': subject,
        'body': body,
        'attachment_path': attachmentPath,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'Pending',
      });

      _emailQueue.insert(0, EmailQueue(
        id: id,
        recipient: recipient,
        subject: subject,
        body: body,
        attachmentPath: attachmentPath,
        status: 'Pending',
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to queue email: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markEmailSent(int emailId) async {
    try {
      await _db.update('email_queue', {
        'status': 'Sent',
        'sent_at': DateTime.now().toIso8601String(),
      }, id: emailId);

      final index = _emailQueue.indexWhere((e) => e.id == emailId);
      if (index != -1) {
        _emailQueue[index] = EmailQueue(
          id: _emailQueue[index].id,
          recipient: _emailQueue[index].recipient,
          subject: _emailQueue[index].subject,
          body: _emailQueue[index].body,
          attachmentPath: _emailQueue[index].attachmentPath,
          createdAt: _emailQueue[index].createdAt,
          sentAt: DateTime.now(),
          status: 'Sent',
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to mark email sent: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createMemo({
    required String title,
    required String content,
    required int createdBy,
    required String createdByName,
    String priority = 'Normal',
    DateTime? expiresAt,
    bool isPinned = false,
  }) async {
    try {
      final id = await _db.insert('internal_memos', {
        'title': title,
        'content': content,
        'created_by': createdBy,
        'created_by_name': createdByName,
        'priority': priority,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'is_pinned': isPinned ? 1 : 0,
      });

      _memos.insert(0, InternalMemo(
        id: id,
        title: title,
        content: content,
        createdBy: createdBy,
        createdByName: createdByName,
        priority: priority,
        expiresAt: expiresAt,
        isPinned: isPinned,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create memo: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMemo(int memoId) async {
    try {
      await _db.delete('internal_memos', id: memoId);
      _memos.removeWhere((m) => m.id == memoId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete memo: $e';
      notifyListeners();
      return false;
    }
  }
}
