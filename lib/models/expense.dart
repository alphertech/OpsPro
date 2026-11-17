import '../utils/money.dart';

class Expense {
  int? id;
  String category;
  String? description;
  Money amount;
  DateTime expenseDate;
  String? paymentMethod;
  String? reference;
  String? receiptPath;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  Expense({
    this.id,
    required this.category,
    this.description,
    required this.amount,
    DateTime? expenseDate,
    this.paymentMethod,
    this.reference,
    this.receiptPath,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : expenseDate = expenseDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'description': description,
      'amount': amount.asDouble,
      'expense_date': expenseDate.toIso8601String(),
      'payment_method': paymentMethod,
      'reference': reference,
      'receipt_path': receiptPath,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      category: map['category'],
      description: map['description'],
      amount: Money.fromDouble((map['amount'] as num?)?.toDouble() ?? 0.0),
      expenseDate: DateTime.parse(map['expense_date']),
      paymentMethod: map['payment_method'],
      reference: map['reference'],
      receiptPath: map['receipt_path'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Expense copyWith({
    int? id,
    String? category,
    String? description,
    Money? amount,
    DateTime? expenseDate,
    String? paymentMethod,
    String? reference,
    String? receiptPath,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reference: reference ?? this.reference,
      receiptPath: receiptPath ?? this.receiptPath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
