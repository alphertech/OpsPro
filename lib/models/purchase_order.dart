import '../utils/money.dart';

class PurchaseOrder {
  int? id;
  String poNumber;
  int supplierId;
  String supplierName;
  DateTime orderDate;
  DateTime? expectedDate;
  String status;
  Money subtotal;
  Money taxAmount;
  Money shippingCost;
  Money insuranceCost;
  Money customsFee;
  Money otherCosts;
  Money totalAmount;
  Money amountPaid;
  String? notes;
  int? createdBy;
  DateTime createdAt;
  DateTime updatedAt;

  PurchaseOrder({
    this.id,
    required this.poNumber,
    required this.supplierId,
    required this.supplierName,
    DateTime? orderDate,
    this.expectedDate,
    this.status = 'Draft',
    this.subtotal = Money.zero,
    this.taxAmount = Money.zero,
    this.shippingCost = Money.zero,
    this.insuranceCost = Money.zero,
    this.customsFee = Money.zero,
    this.otherCosts = Money.zero,
    this.totalAmount = Money.zero,
    this.amountPaid = Money.zero,
    this.notes,
    this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : orderDate = orderDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Money get landedCost => subtotal + shippingCost + insuranceCost + customsFee + otherCosts;
  Money get balanceDue => totalAmount - amountPaid;
  bool get isFullyPaid => balanceDue.compareTo(Money.zero) <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'po_number': poNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'order_date': orderDate.toIso8601String(),
      'expected_date': expectedDate?.toIso8601String(),
      'status': status,
      'subtotal': subtotal.asDouble,
      'tax_amount': taxAmount.asDouble,
      'shipping_cost': shippingCost.asDouble,
      'insurance_cost': insuranceCost.asDouble,
      'customs_fee': customsFee.asDouble,
      'other_costs': otherCosts.asDouble,
      'total_amount': totalAmount.asDouble,
      'amount_paid': amountPaid.asDouble,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      id: map['id'],
      poNumber: map['po_number'],
      supplierId: map['supplier_id'],
      supplierName: map['supplier_name'],
      orderDate: DateTime.parse(map['order_date']),
      expectedDate: map['expected_date'] != null ? DateTime.parse(map['expected_date']) : null,
      status: map['status'] ?? 'Draft',
      subtotal: Money.fromDouble((map['subtotal'] as num?)?.toDouble() ?? 0.0),
      taxAmount: Money.fromDouble((map['tax_amount'] as num?)?.toDouble() ?? 0.0),
      shippingCost: Money.fromDouble((map['shipping_cost'] as num?)?.toDouble() ?? 0.0),
      insuranceCost: Money.fromDouble((map['insurance_cost'] as num?)?.toDouble() ?? 0.0),
      customsFee: Money.fromDouble((map['customs_fee'] as num?)?.toDouble() ?? 0.0),
      otherCosts: Money.fromDouble((map['other_costs'] as num?)?.toDouble() ?? 0.0),
      totalAmount: Money.fromDouble((map['total_amount'] as num?)?.toDouble() ?? 0.0),
      amountPaid: Money.fromDouble((map['amount_paid'] as num?)?.toDouble() ?? 0.0),
      notes: map['notes'],
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  PurchaseOrder copyWith({
    int? id,
    String? poNumber,
    int? supplierId,
    String? supplierName,
    DateTime? orderDate,
    DateTime? expectedDate,
    String? status,
    Money? subtotal,
    Money? taxAmount,
    Money? shippingCost,
    Money? insuranceCost,
    Money? customsFee,
    Money? otherCosts,
    Money? totalAmount,
    Money? amountPaid,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      poNumber: poNumber ?? this.poNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      orderDate: orderDate ?? this.orderDate,
      expectedDate: expectedDate ?? this.expectedDate,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      insuranceCost: insuranceCost ?? this.insuranceCost,
      customsFee: customsFee ?? this.customsFee,
      otherCosts: otherCosts ?? this.otherCosts,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PurchaseOrderItem {
  int? id;
  int? poId;
  int productId;
  String productName;
  String? productSku;
  double quantity;
  String unit;
  Money unitPrice;
  double receivedQuantity;
  Money totalPrice;
  Money landedCostPerUnit;

  PurchaseOrderItem({
    this.id,
    this.poId,
    required this.productId,
    required this.productName,
    this.productSku,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.receivedQuantity = 0,
    this.totalPrice = Money.zero,
    this.landedCostPerUnit = Money.zero,
  });

  double get remainingQuantity => quantity - receivedQuantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'po_id': poId,
      'product_id': productId,
      'product_name': productName,
      'product_sku': productSku,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice.asDouble,
      'received_quantity': receivedQuantity,
      'total_price': totalPrice.asDouble,
      'landed_cost_per_unit': landedCostPerUnit.asDouble,
    };
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id: map['id'],
      poId: map['po_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      productSku: map['product_sku'],
      quantity: map['quantity'],
      unit: map['unit'],
      unitPrice: Money.fromDouble((map['unit_price'] as num?)?.toDouble() ?? 0.0),
      receivedQuantity: map['received_quantity'] ?? 0,
      totalPrice: Money.fromDouble((map['total_price'] as num?)?.toDouble() ?? 0.0),
      landedCostPerUnit: Money.fromDouble((map['landed_cost_per_unit'] as num?)?.toDouble() ?? 0.0),
    );
  }
}
