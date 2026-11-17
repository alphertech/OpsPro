import '../utils/money.dart';

class Sale {
  int? id;
  String invoiceNumber;
  DateTime saleDate;
  int? customerId;
  String? customerName;
  int? userId;
  String? userName;
  Money subtotal;
  Money discountAmount;
  Money taxAmount;
  Money totalAmount;
  Money amountPaid;
  Money balanceDue;
  String paymentMethod;
  String? paymentReference;
  String status;
  String? notes;
  bool isCredit;
  DateTime? dueDate;
  List<SaleItem> items;
  DateTime createdAt;
  DateTime updatedAt;

  Sale({
    this.id,
    required this.invoiceNumber,
    DateTime? saleDate,
    this.customerId,
    this.customerName,
    this.userId,
    this.userName,
    this.subtotal = Money.zero,
    this.discountAmount = Money.zero,
    this.taxAmount = Money.zero,
    this.totalAmount = Money.zero,
    this.amountPaid = Money.zero,
    this.balanceDue = Money.zero,
    required this.paymentMethod,
    this.paymentReference,
    this.status = 'Completed',
    this.notes,
    this.isCredit = false,
    this.dueDate,
    this.items = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : saleDate = saleDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get discountPercentage =>
      subtotal.asDouble > 0 ? (discountAmount.asDouble / subtotal.asDouble) * 100 : 0;
  bool get isFullyPaid => balanceDue.compareTo(Money.zero) <= 0;
  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isFullyPaid;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'sale_date': saleDate.toIso8601String(),
      'customer_id': customerId,
      'customer_name': customerName,
      'user_id': userId,
      'user_name': userName,
      'subtotal': subtotal.asDouble,
      'discount_amount': discountAmount.asDouble,
      'tax_amount': taxAmount.asDouble,
      'total_amount': totalAmount.asDouble,
      'amount_paid': amountPaid.asDouble,
      'balance_due': balanceDue.asDouble,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'status': status,
      'notes': notes,
      'is_credit': isCredit ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      saleDate: DateTime.parse(map['sale_date']),
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      userId: map['user_id'],
      userName: map['user_name'],
      subtotal: Money.fromDouble((map['subtotal'] as num).toDouble()),
      discountAmount: Money.fromDouble((map['discount_amount'] as num).toDouble()),
      taxAmount: Money.fromDouble((map['tax_amount'] as num).toDouble()),
      totalAmount: Money.fromDouble((map['total_amount'] as num).toDouble()),
      amountPaid: Money.fromDouble((map['amount_paid'] as num).toDouble()),
      balanceDue: Money.fromDouble((map['balance_due'] as num).toDouble()),
      paymentMethod: map['payment_method'],
      paymentReference: map['payment_reference'],
      status: map['status'],
      notes: map['notes'],
      isCredit: map['is_credit'] == 1,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      items: const [],
    );
  }

  Sale copyWithItems(List<SaleItem> items) {
    return Sale(
      id: id,
      invoiceNumber: invoiceNumber,
      saleDate: saleDate,
      customerId: customerId,
      customerName: customerName,
      userId: userId,
      userName: userName,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      amountPaid: amountPaid,
      balanceDue: balanceDue,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
      status: status,
      notes: notes,
      isCredit: isCredit,
      dueDate: dueDate,
      items: items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class SaleItem {
  int? id;
  int? saleId;
  int productId;
  String productName;
  String? productSku;
  double quantity;
  String unit;
  Money unitPrice;
  Money purchaseCost;
  Money discountAmount;
  Money taxAmount;
  Money totalAmount;
  String? batchNumber;
  double? weight;

  SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    this.productSku,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.purchaseCost,
    this.discountAmount = Money.zero,
    this.taxAmount = Money.zero,
    required this.totalAmount,
    this.batchNumber,
    this.weight,
  });

  Money get profit => totalAmount - Money.fromDouble(purchaseCost.asDouble * quantity);
  double get profitMargin => totalAmount.asDouble > 0 ? (profit.asDouble / totalAmount.asDouble) * 100 : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'product_sku': productSku,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice.asDouble,
      'purchase_cost': purchaseCost.asDouble,
      'discount_amount': discountAmount.asDouble,
      'tax_amount': taxAmount.asDouble,
      'total_amount': totalAmount.asDouble,
      'batch_number': batchNumber,
      'weight': weight,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      productSku: map['product_sku'],
      quantity: map['quantity'],
      unit: map['unit'],
      unitPrice: Money.fromDouble((map['unit_price'] as num).toDouble()),
      purchaseCost: Money.fromDouble((map['purchase_cost'] as num).toDouble()),
      discountAmount: Money.fromDouble(((map['discount_amount'] ?? 0) as num).toDouble()),
      taxAmount: Money.fromDouble(((map['tax_amount'] ?? 0) as num).toDouble()),
      totalAmount: Money.fromDouble((map['total_amount'] as num).toDouble()),
      batchNumber: map['batch_number'],
      weight: map['weight'],
    );
  }
}
