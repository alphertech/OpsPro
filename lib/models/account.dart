import '../utils/money.dart';

class Account {
  int? id;
  String code;
  String name;
  String type;
  String? subType;
  Money balance;
  int? parentId;
  bool isActive;
  String? description;
  DateTime createdAt;
  DateTime updatedAt;

  Account({
    this.id,
    required this.code,
    required this.name,
    required this.type,
    this.subType,
    this.balance = Money.zero,
    this.parentId,
    this.isActive = true,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type,
      'sub_type': subType,
      'balance': balance.asDouble,
      'parent_id': parentId,
      'is_active': isActive ? 1 : 0,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      type: map['type'],
      subType: map['sub_type'],
      balance: Money.fromDouble((map['balance'] as num?)?.toDouble() ?? 0.0),
      parentId: map['parent_id'],
      isActive: map['is_active'] == 1,
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Account copyWith({
    int? id,
    String? code,
    String? name,
    String? type,
    String? subType,
    Money? balance,
    int? parentId,
    bool? isActive,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      subType: subType ?? this.subType,
      balance: balance ?? this.balance,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class JournalEntry {
  int? id;
  String entryNumber;
  DateTime entryDate;
  String description;
  Money amount;
  int debitAccountId;
  int creditAccountId;
  String? reference;
  String? notes;
  int? userId;
  DateTime createdAt;

  JournalEntry({
    this.id,
    required this.entryNumber,
    DateTime? entryDate,
    required this.description,
    required this.amount,
    required this.debitAccountId,
    required this.creditAccountId,
    this.reference,
    this.notes,
    this.userId,
    DateTime? createdAt,
  })  : entryDate = entryDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entry_number': entryNumber,
      'entry_date': entryDate.toIso8601String(),
      'description': description,
      'amount': amount.asDouble,
      'debit_account_id': debitAccountId,
      'credit_account_id': creditAccountId,
      'reference': reference,
      'notes': notes,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      entryNumber: map['entry_number'],
      entryDate: DateTime.parse(map['entry_date']),
      description: map['description'],
      amount: Money.fromDouble((map['amount'] as num?)?.toDouble() ?? 0.0),
      debitAccountId: map['debit_account_id'],
      creditAccountId: map['credit_account_id'],
      reference: map['reference'],
      notes: map['notes'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class BankReconciliation {
  int? id;
  int bankAccountId;
  DateTime statementDate;
  double statementBalance;
  double bookBalance;
  double adjustedBalance;
  bool isReconciled;
  DateTime? reconciledAt;
  String? notes;
  DateTime createdAt;

  BankReconciliation({
    this.id,
    required this.bankAccountId,
    DateTime? statementDate,
    required this.statementBalance,
    required this.bookBalance,
    this.adjustedBalance = 0,
    this.isReconciled = false,
    this.reconciledAt,
    this.notes,
    DateTime? createdAt,
  })  : statementDate = statementDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  double get difference => statementBalance - adjustedBalance;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bank_account_id': bankAccountId,
      'statement_date': statementDate.toIso8601String(),
      'statement_balance': statementBalance,
      'book_balance': bookBalance,
      'adjusted_balance': adjustedBalance,
      'is_reconciled': isReconciled ? 1 : 0,
      'reconciled_at': reconciledAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BankReconciliation.fromMap(Map<String, dynamic> map) {
    return BankReconciliation(
      id: map['id'],
      bankAccountId: map['bank_account_id'],
      statementDate: DateTime.parse(map['statement_date']),
      statementBalance: map['statement_balance'],
      bookBalance: map['book_balance'],
      adjustedBalance: map['adjusted_balance'] ?? 0,
      isReconciled: map['is_reconciled'] == 1,
      reconciledAt: map['reconciled_at'] != null ? DateTime.parse(map['reconciled_at']) : null,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class PettyCashTransaction {
  int? id;
  DateTime transactionDate;
  String description;
  Money amount;
  String type;
  String? paidTo;
  String? receivedFrom;
  String? receiptNumber;
  int? userId;
  DateTime createdAt;

  PettyCashTransaction({
    this.id,
    DateTime? transactionDate,
    required this.description,
    required this.amount,
    required this.type,
    this.paidTo,
    this.receivedFrom,
    this.receiptNumber,
    this.userId,
    DateTime? createdAt,
  })  : transactionDate = transactionDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_date': transactionDate.toIso8601String(),
      'description': description,
      'amount': amount.asDouble,
      'type': type,
      'paid_to': paidTo,
      'received_from': receivedFrom,
      'receipt_number': receiptNumber,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PettyCashTransaction.fromMap(Map<String, dynamic> map) {
    return PettyCashTransaction(
      id: map['id'],
      transactionDate: DateTime.parse(map['transaction_date']),
      description: map['description'],
      amount: map['amount'],
      type: map['type'],
      paidTo: map['paid_to'],
      receivedFrom: map['received_from'],
      receiptNumber: map['receipt_number'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
