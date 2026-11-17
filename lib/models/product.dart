import '../utils/money.dart';

class Product {
  int? id;
  String name;
  String sku;
  String? barcode;
  int categoryId;
  String? categoryName;
  Money purchasePrice;
  Money averageCost;
  Money sellingPrice;
  Money wholesalePrice;
  Money? vipPrice;
  double currentStock;
  double minimumStock;
  double maximumStock;
  String baseUnit;
  String sellingUnit;
  double conversionFactor;
  double? weightPerUnit;
  double? volumePerUnit;
  String? location;
  String? batchNumber;
  DateTime? manufacturingDate;
  DateTime? expiryDate;
  int? supplierId;
  String? supplierName;
  bool isActive;
  String? imagePath;
  DateTime createdAt;
  DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.sku,
    this.barcode,
    required this.categoryId,
    this.categoryName,
    required this.purchasePrice,
    required this.averageCost,
    required this.sellingPrice,
    this.wholesalePrice = Money.zero,
    this.vipPrice,
    required this.currentStock,
    required this.minimumStock,
    this.maximumStock = 999999,
    required this.baseUnit,
    required this.sellingUnit,
    this.conversionFactor = 1.0,
    this.weightPerUnit,
    this.volumePerUnit,
    this.location,
    this.batchNumber,
    this.manufacturingDate,
    this.expiryDate,
    this.supplierId,
    this.supplierName,
    this.isActive = true,
    this.imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Money get profitPerUnit => sellingPrice - averageCost;
  double get profitMargin => sellingPrice.asDouble > 0 ? (profitPerUnit.asDouble / sellingPrice.asDouble) * 100 : 0;
  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isNearExpiry =>
      expiryDate != null && expiryDate!.difference(DateTime.now()).inDays <= 30;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category_id': categoryId,
      'category_name': categoryName,
      'purchase_price': purchasePrice.asDouble,
      'average_cost': averageCost.asDouble,
      'selling_price': sellingPrice.asDouble,
      'wholesale_price': wholesalePrice.asDouble,
      'vip_price': vipPrice?.asDouble,
      'current_stock': currentStock,
      'minimum_stock': minimumStock,
      'maximum_stock': maximumStock,
      'base_unit': baseUnit,
      'selling_unit': sellingUnit,
      'conversion_factor': conversionFactor,
      'weight_per_unit': weightPerUnit,
      'volume_per_unit': volumePerUnit,
      'location': location,
      'batch_number': batchNumber,
      'manufacturing_date': manufacturingDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'is_active': isActive ? 1 : 0,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      sku: map['sku'],
      barcode: map['barcode'],
      categoryId: map['category_id'],
      categoryName: map['category_name'],
      purchasePrice: Money.fromDouble((map['purchase_price'] as num).toDouble()),
      averageCost: Money.fromDouble((map['average_cost'] as num).toDouble()),
      sellingPrice: Money.fromDouble((map['selling_price'] as num).toDouble()),
      wholesalePrice: Money.fromDouble(((map['wholesale_price'] ?? 0) as num).toDouble()),
      vipPrice: map['vip_price'] != null ? Money.fromDouble((map['vip_price'] as num).toDouble()) : null,
      currentStock: map['current_stock'],
      minimumStock: map['minimum_stock'],
      maximumStock: map['maximum_stock'] ?? 999999,
      baseUnit: map['base_unit'],
      sellingUnit: map['selling_unit'],
      conversionFactor: map['conversion_factor'] ?? 1.0,
      weightPerUnit: map['weight_per_unit'],
      volumePerUnit: map['volume_per_unit'],
      location: map['location'],
      batchNumber: map['batch_number'],
      manufacturingDate: map['manufacturing_date'] != null
          ? DateTime.parse(map['manufacturing_date'])
          : null,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'])
          : null,
      supplierId: map['supplier_id'],
      supplierName: map['supplier_name'],
      isActive: map['is_active'] == 1,
      imagePath: map['image_path'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    String? barcode,
    int? categoryId,
    String? categoryName,
    Money? purchasePrice,
    Money? averageCost,
    Money? sellingPrice,
    Money? wholesalePrice,
    Money? vipPrice,
    double? currentStock,
    double? minimumStock,
    double? maximumStock,
    String? baseUnit,
    String? sellingUnit,
    double? conversionFactor,
    double? weightPerUnit,
    double? volumePerUnit,
    String? location,
    String? batchNumber,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    int? supplierId,
    String? supplierName,
    bool? isActive,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      averageCost: averageCost ?? this.averageCost,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      vipPrice: vipPrice ?? this.vipPrice,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      baseUnit: baseUnit ?? this.baseUnit,
      sellingUnit: sellingUnit ?? this.sellingUnit,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      weightPerUnit: weightPerUnit ?? this.weightPerUnit,
      volumePerUnit: volumePerUnit ?? this.volumePerUnit,
      location: location ?? this.location,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expiryDate: expiryDate ?? this.expiryDate,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      isActive: isActive ?? this.isActive,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
