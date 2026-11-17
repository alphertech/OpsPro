import '../utils/money.dart';

class AuditLog {
  int? id;
  String tableName;
  int? recordId;
  String action;
  String? oldValues;
  String? newValues;
  int? userId;
  String? userName;
  DateTime createdAt;

  AuditLog({
    this.id,
    required this.tableName,
    this.recordId,
    required this.action,
    this.oldValues,
    this.newValues,
    this.userId,
    this.userName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'old_values': oldValues,
      'new_values': newValues,
      'user_id': userId,
      'user_name': userName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'],
      tableName: map['table_name'],
      recordId: map['record_id'],
      action: map['action'],
      oldValues: map['old_values'],
      newValues: map['new_values'],
      userId: map['user_id'],
      userName: map['user_name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class Currency {
  int? id;
  String code;
  String name;
  String symbol;
  double exchangeRate;
  bool isDefault;
  bool isActive;
  DateTime updatedAt;

  Currency({
    this.id,
    required this.code,
    required this.name,
    required this.symbol,
    this.exchangeRate = 1,
    this.isDefault = false,
    this.isActive = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'symbol': symbol,
      'exchange_rate': exchangeRate,
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      symbol: map['symbol'],
      exchangeRate: map['exchange_rate'] ?? 1,
      isDefault: map['is_default'] == 1,
      isActive: map['is_active'] == 1,
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class TaxRate {
  int? id;
  String name;
  double rate;
  String? description;
  bool isDefault;
  bool isActive;
  DateTime createdAt;

  TaxRate({
    this.id,
    required this.name,
    this.rate = 0,
    this.description,
    this.isDefault = false,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rate': rate,
      'description': description,
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TaxRate.fromMap(Map<String, dynamic> map) {
    return TaxRate(
      id: map['id'],
      name: map['name'],
      rate: map['rate'] ?? 0,
      description: map['description'],
      isDefault: map['is_default'] == 1,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}


class RecurringInvoice {
  int? id;
  String name;
  int? customerId;
  String? customerName;
  String frequency;
  DateTime startDate;
  DateTime? endDate;
  DateTime? lastGenerated;
  DateTime nextDue;
  Money amount;
  Money taxAmount;
  Money totalAmount;
  String? notes;
  String status;
  DateTime createdAt;

  RecurringInvoice({
    this.id,
    required this.name,
    this.customerId,
    this.customerName,
    this.frequency = 'Monthly',
    DateTime? startDate,
    this.endDate,
    this.lastGenerated,
    DateTime? nextDue,
    this.amount = Money.zero,
    this.taxAmount = Money.zero,
    this.totalAmount = Money.zero,
    this.notes,
    this.status = 'Active',
    DateTime? createdAt,
  })  : startDate = startDate ?? DateTime.now(),
        nextDue = nextDue ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'customer_id': customerId,
      'customer_name': customerName,
      'frequency': frequency,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'last_generated': lastGenerated?.toIso8601String(),
      'next_due': nextDue.toIso8601String(),
      'amount': amount.asDouble,
      'tax_amount': taxAmount.asDouble,
      'total_amount': totalAmount.asDouble,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RecurringInvoice.fromMap(Map<String, dynamic> map) {
    return RecurringInvoice(
      id: map['id'],
      name: map['name'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      frequency: map['frequency'] ?? 'Monthly',
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      lastGenerated: map['last_generated'] != null ? DateTime.parse(map['last_generated']) : null,
      nextDue: DateTime.parse(map['next_due']),
      amount: Money.fromDouble((map['amount'] as num?)?.toDouble() ?? 0.0),
      taxAmount: Money.fromDouble((map['tax_amount'] as num?)?.toDouble() ?? 0.0),
      totalAmount: Money.fromDouble((map['total_amount'] as num?)?.toDouble() ?? 0.0),
      notes: map['notes'],
      status: map['status'] ?? 'Active',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class CreditMemo {
  int? id;
  String memoNumber;
  int saleId;
  String invoiceNumber;
  int? customerId;
  String? customerName;
  DateTime memoDate;
  Money amount;
  Money taxAmount;
  Money totalAmount;
  String reason;
  String status;
  DateTime createdAt;

  CreditMemo({
    this.id,
    required this.memoNumber,
    required this.saleId,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    DateTime? memoDate,
    this.amount = Money.zero,
    this.taxAmount = Money.zero,
    this.totalAmount = Money.zero,
    required this.reason,
    this.status = 'Issued',
    DateTime? createdAt,
  })  : memoDate = memoDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memo_number': memoNumber,
      'sale_id': saleId,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'memo_date': memoDate.toIso8601String(),
      'amount': amount.asDouble,
      'tax_amount': taxAmount.asDouble,
      'total_amount': totalAmount.asDouble,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CreditMemo.fromMap(Map<String, dynamic> map) {
    return CreditMemo(
      id: map['id'],
      memoNumber: map['memo_number'],
      saleId: map['sale_id'],
      invoiceNumber: map['invoice_number'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      memoDate: DateTime.parse(map['memo_date']),
      amount: Money.fromDouble((map['amount'] as num?)?.toDouble() ?? 0.0),
      taxAmount: Money.fromDouble((map['tax_amount'] as num?)?.toDouble() ?? 0.0),
      totalAmount: Money.fromDouble((map['total_amount'] as num?)?.toDouble() ?? 0.0),
      reason: map['reason'],
      status: map['status'] ?? 'Issued',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class Warehouse {
  int? id;
  String name;
  String? code;
  String? address;
  String? manager;
  bool isDefault;
  bool isActive;
  DateTime createdAt;

  Warehouse({
    this.id,
    required this.name,
    this.code,
    this.address,
    this.manager,
    this.isDefault = false,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'manager': manager,
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      address: map['address'],
      manager: map['manager'],
      isDefault: map['is_default'] == 1,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class StockTransfer {
  int? id;
  String transferNumber;
  int fromWarehouseId;
  int toWarehouseId;
  String fromWarehouseName;
  String toWarehouseName;
  DateTime transferDate;
  String status;
  String? notes;
  int? createdBy;
  DateTime createdAt;

  StockTransfer({
    this.id,
    required this.transferNumber,
    required this.fromWarehouseId,
    required this.toWarehouseId,
    required this.fromWarehouseName,
    required this.toWarehouseName,
    DateTime? transferDate,
    this.status = 'Pending',
    this.notes,
    this.createdBy,
    DateTime? createdAt,
  })  : transferDate = transferDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transfer_number': transferNumber,
      'from_warehouse_id': fromWarehouseId,
      'to_warehouse_id': toWarehouseId,
      'from_warehouse_name': fromWarehouseName,
      'to_warehouse_name': toWarehouseName,
      'transfer_date': transferDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockTransfer.fromMap(Map<String, dynamic> map) {
    return StockTransfer(
      id: map['id'],
      transferNumber: map['transfer_number'],
      fromWarehouseId: map['from_warehouse_id'],
      toWarehouseId: map['to_warehouse_id'],
      fromWarehouseName: map['from_warehouse_name'],
      toWarehouseName: map['to_warehouse_name'],
      transferDate: DateTime.parse(map['transfer_date']),
      status: map['status'] ?? 'Pending',
      notes: map['notes'],
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class EmailQueue {
  int? id;
  String recipient;
  String subject;
  String body;
  String? attachmentPath;
  DateTime createdAt;
  DateTime? sentAt;
  String status;

  EmailQueue({
    this.id,
    required this.recipient,
    required this.subject,
    required this.body,
    this.attachmentPath,
    DateTime? createdAt,
    this.sentAt,
    this.status = 'Pending',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipient': recipient,
      'subject': subject,
      'body': body,
      'attachment_path': attachmentPath,
      'created_at': createdAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'status': status,
    };
  }

  factory EmailQueue.fromMap(Map<String, dynamic> map) {
    return EmailQueue(
      id: map['id'],
      recipient: map['recipient'],
      subject: map['subject'],
      body: map['body'],
      attachmentPath: map['attachment_path'],
      createdAt: DateTime.parse(map['created_at']),
      sentAt: map['sent_at'] != null ? DateTime.parse(map['sent_at']) : null,
      status: map['status'] ?? 'Pending',
    );
  }
}

class InternalMemo {
  int? id;
  String title;
  String content;
  int createdBy;
  String createdByName;
  String priority;
  DateTime createdAt;
  DateTime? expiresAt;
  bool isPinned;

  InternalMemo({
    this.id,
    required this.title,
    required this.content,
    required this.createdBy,
    required this.createdByName,
    this.priority = 'Normal',
    DateTime? createdAt,
    this.expiresAt,
    this.isPinned = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_pinned': isPinned ? 1 : 0,
    };
  }

  factory InternalMemo.fromMap(Map<String, dynamic> map) {
    return InternalMemo(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdBy: map['created_by'],
      createdByName: map['created_by_name'],
      priority: map['priority'] ?? 'Normal',
      createdAt: DateTime.parse(map['created_at']),
      expiresAt: map['expires_at'] != null ? DateTime.parse(map['expires_at']) : null,
      isPinned: map['is_pinned'] == 1,
    );
  }
}
