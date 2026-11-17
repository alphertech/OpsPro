import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/database_service.dart';
import '../utils/money.dart';

class CartItem {
  final int productId;
  final String name;
  final String sku;
  final double quantity;
  final Money price;
  final String unit;
  final Money discount;

  CartItem({
    required this.productId,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.price,
    required this.unit,
    this.discount = Money.zero,
  });

  CartItem copyWith({
    int? productId,
    String? name,
    String? sku,
    double? quantity,
    Money? price,
    String? unit,
    Money? discount,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      discount: discount ?? this.discount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'sku': sku,
      'quantity': quantity,
      'price': price.asDouble,
      'unit': unit,
      'discount': discount.asDouble,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      price: Money.fromDouble((json['price'] as num).toDouble()),
      unit: json['unit'] as String,
      discount: Money.fromDouble((json['discount'] as num?)?.toDouble() ?? 0.0),
    );
  }
}

class CartProvider extends ChangeNotifier {
  // Make these instance variables instead of static
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  bool _initFailed = false;
  String? _initError;
  Completer<void>? _initCompleter;

  final DatabaseService _db = DatabaseService();
  final List<CartItem> _items = [];
  String _paymentMethod = 'Cash';
  int? _selectedCustomerId;
  String? _customerName;
  String _notes = '';
  double _taxRate = 0.0;

  // Static singleton pattern to prevent multiple instances
  static CartProvider? _instance;

  factory CartProvider() {
    _instance ??= CartProvider._internal();
    return _instance!;
  }

  CartProvider._internal() {
    _init();
  }

  // Public getters
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  Money get subtotal => Money.fromDouble(_items.fold(
      0, (sum, item) => sum + (item.quantity * item.price.asDouble)));
  Money get taxAmount => Money.fromDouble(subtotal.asDouble * _taxRate);
  Money get totalDiscount =>
      _items.fold(Money.zero, (sum, item) => sum + item.discount);
  Money get total => subtotal + taxAmount - totalDiscount;
  double get taxRate => _taxRate;
  bool get isEmpty => _items.isEmpty;
  String get paymentMethod => _paymentMethod;
  int? get selectedCustomerId => _selectedCustomerId;
  String? get customerName => _customerName;
  String get notes => _notes;
  bool get hasUnfinishedCart => _items.isNotEmpty;
  bool get isInitialized => _isInitialized;
  bool get initFailed => _initFailed;
  String? get initError => _initError;

  // Static ready getter that works with singleton
  static Future<void> get ready async {
    try {
      final instance = CartProvider();
      await instance._waitForInit();
    } catch (e) {
      throw Exception('CartProvider initialization failed: $e');
    }
  }

  Future<void> _waitForInit() async {
    if (_isInitialized) return;
    if (_initFailed) {
      throw Exception(_initError ?? 'CartProvider initialization failed');
    }
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      await _initCompleter!.future;
    }
  }

  Future<void> _init() async {
    // Prevent multiple initialization attempts
    if (_isInitialized || _initFailed) return;

    if (_initCompleter == null || _initCompleter!.isCompleted) {
      _initCompleter = Completer<void>();
    }

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      _initFailed = false;
      _initError = null;

      if (!_initCompleter!.isCompleted) {
        _initCompleter!.complete();
      }

      // Load cart after successful initialization
      _loadCart();
    } catch (e) {
      _isInitialized = false;
      _initFailed = true;
      _initError = 'Failed to initialize SharedPreferences: $e';

      if (!_initCompleter!.isCompleted) {
        _initCompleter!.completeError(e);
      }

      if (kDebugMode) {
        debugPrint('CartProvider initialization failed: $e');
      }
      rethrow;
    }
  }

  // Static init method for backward compatibility
  static Future<void> init() async {
    return CartProvider()._waitForInit();
  }

  void _loadCart() {
    if (!_isInitialized || _initFailed) {
      if (kDebugMode) {
        debugPrint('Cannot load cart - provider not initialized');
      }
      return;
    }

    try {
      final json = _prefs.getString('saved_cart');
      if (json != null && json.isNotEmpty) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        _fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load cart: $e');
      }
      // Don't throw - just log the error
    }
  }

  Future<void> _saveCart() async {
    if (!_isInitialized || _initFailed) {
      if (kDebugMode) {
        debugPrint('Cannot save cart - provider not initialized');
      }
      return;
    }

    try {
      final json = jsonEncode(toJson());
      await _prefs.setString('saved_cart', json);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to save cart: $e');
      }
      // Don't throw - just log the error
    }
  }

  void _fromJson(Map<String, dynamic> json) {
    // Clear items safely
    _items.clear();

    try {
      final items = json['items'] as List<dynamic>? ?? [];
      final seenProductIds = <int>{};
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final cartItem = CartItem.fromJson(item);
          if (!seenProductIds.contains(cartItem.productId)) {
            seenProductIds.add(cartItem.productId);
            _items.add(cartItem);
          }
        }
      }
      _paymentMethod = json['paymentMethod'] as String? ?? 'Cash';
      _selectedCustomerId = json['selectedCustomerId'] as int?;
      _customerName = json['customerName'] as String?;
      _notes = json['notes'] as String? ?? '';
      _taxRate = (json['taxRate'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error parsing cart JSON: $e');
      }
      // If parsing fails, start with empty cart
      _items.clear();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'items': _items.map((i) => i.toJson()).toList(),
      'paymentMethod': _paymentMethod,
      'selectedCustomerId': _selectedCustomerId,
      'customerName': _customerName,
      'notes': _notes,
      'taxRate': _taxRate,
    };
  }

  factory CartProvider.fromJson(Map<String, dynamic> json) {
    final instance = CartProvider();
    instance._fromJson(json);
    return instance;
  }

  void addItem(Product product, {int quantity = 1}) {
    // Validate product
    if (product.id == null) {
      throw Exception('Product ID is null');
    }

    if (product.currentStock <= 0) {
      throw Exception('Product is out of stock');
    }

    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }

    try {
      final existingIndex = _items.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingIndex >= 0) {
        final existing = _items[existingIndex];
        final newQuantity = existing.quantity + quantity;

        if (newQuantity > product.currentStock) {
          throw Exception(
              'Insufficient stock. Available: ${product.currentStock}');
        }

        _items[existingIndex] = existing.copyWith(quantity: newQuantity);
      } else {
        if (quantity > product.currentStock) {
          throw Exception('Out of stock. Available: ${product.currentStock}');
        }

        _items.add(CartItem(
          productId: product.id!,
          name: product.name,
          sku: product.sku,
          quantity: quantity.toDouble(),
          price: product.sellingPrice,
          unit: product.sellingUnit,
          discount: Money.zero,
        ));
      }

      notifyListeners();
      _saveCart();
    } catch (e) {
      // Re-throw with more context
      throw Exception('Failed to add product "${product.name}": $e');
    }
  }

  void removeItem(int index) {
    if (index < 0 || index >= _items.length) {
      if (kDebugMode) {
        debugPrint('Invalid index for removeItem: $index');
      }
      return;
    }
    _items.removeAt(index);
    notifyListeners();
    _saveCart();
  }

  void updateQuantity(int index, double quantity) {
    if (index < 0 || index >= _items.length) {
      if (kDebugMode) {
        debugPrint('Invalid index for updateQuantity: $index');
      }
      return;
    }

    if (quantity <= 0) {
      removeItem(index);
      return;
    }

    _items[index] = _items[index].copyWith(quantity: quantity);
    notifyListeners();
    _saveCart();
  }

  void clear() {
    _items.clear();
    _selectedCustomerId = null;
    _customerName = null;
    _notes = '';
    notifyListeners();
    _saveCart();
  }

  void setPaymentMethod(String method) {
    if (method.isEmpty) {
      if (kDebugMode) {
        debugPrint('Payment method cannot be empty');
      }
      return;
    }
    _paymentMethod = method;
    notifyListeners();
    _saveCart();
  }

  void setCustomer(int? id, String? name) {
    _selectedCustomerId = id;
    _customerName = name;
    notifyListeners();
    _saveCart();
  }

  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
    _saveCart();
  }

  void setTaxRate(double rate) {
    if (rate < 0) {
      if (kDebugMode) {
        debugPrint('Tax rate cannot be negative');
      }
      return;
    }
    _taxRate = rate;
    notifyListeners();
    _saveCart();
  }

  Future<Sale> toSale({required int userId, required String userName}) async {
    if (_items.isEmpty) {
      throw Exception('Cart is empty');
    }

    // Validate all items before creating sale
    for (final item in _items) {
      if (item.quantity <= 0) {
        throw Exception('Invalid quantity for ${item.name}');
      }
      if (item.productId <= 0) {
        throw Exception('Invalid product ID for ${item.name}');
      }
    }

    final saleItems = <SaleItem>[];

    try {
      // Get product costs in a single query
      final productIds = _items.map((i) => i.productId).toList();
      final productMaps = <int, Map<String, dynamic>>{};

      if (productIds.isNotEmpty) {
        final placeholders = List.filled(productIds.length, '?').join(',');
        final rows = await _db.query(
          'products',
          where: 'id IN ($placeholders)',
          whereArgs: productIds,
        );
        for (final row in rows) {
          final id = row['id'] as int?;
          if (id != null) {
            productMaps[id] = row;
          }
        }
      }

      for (final item in _items) {
        final productMap = productMaps[item.productId];
        final purchaseCost = productMap != null
            ? Money.fromDouble(
                (productMap['average_cost'] as num?)?.toDouble() ?? 0.0)
            : Money.zero;

        final itemTotal = item.quantity * item.price.asDouble;
        final itemDiscount = item.discount.asDouble;
        final itemNetTotal = itemTotal - itemDiscount;

        saleItems.add(SaleItem(
          productId: item.productId,
          productName: item.name,
          productSku: item.sku,
          quantity: item.quantity,
          unit: item.unit,
          unitPrice: item.price,
          purchaseCost: purchaseCost,
          discountAmount: item.discount,
          taxAmount: Money.zero,
          totalAmount: Money.fromDouble(itemNetTotal),
        ));
      }

      final now = DateTime.now();
      final invoiceNumber =
          'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 1000000}';

      final isCredit = _paymentMethod == 'Credit';

      return Sale(
        invoiceNumber: invoiceNumber,
        customerId: _selectedCustomerId,
        customerName: _customerName ?? 'Walk-in Customer',
        userId: userId,
        userName: userName,
        subtotal: subtotal,
        discountAmount: totalDiscount,
        taxAmount: taxAmount,
        totalAmount: total,
        amountPaid: isCredit ? Money.zero : total,
        balanceDue: isCredit ? total : Money.zero,
        paymentMethod: _paymentMethod,
        status: 'Completed',
        notes: _notes,
        isCredit: isCredit,
        dueDate: isCredit ? now.add(const Duration(days: 30)) : null,
        items: saleItems,
      );
    } catch (e) {
      throw Exception('Failed to create sale: $e');
    }
  }

  @override
  void dispose() {
    // Save cart before disposing if still initialized
    if (_isInitialized && !_initFailed) {
      _saveCart();
    }
    super.dispose();
  }
}
