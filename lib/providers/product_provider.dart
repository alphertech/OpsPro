import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class ProductProvider extends ChangeNotifier {
  static const int _pageSize = 50;
  final DatabaseService _db = DatabaseService();
  List<Product> _products = [];
  List<Product> _allProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMore = true;
  bool _loaded = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock && p.isActive).toList();

  List<String> get categories =>
      _products.where((p) => p.isActive).map((p) => p.categoryName ?? 'Uncategorized').toSet().toList();

  List<Product> filteredProducts({String? searchQuery, String? category, bool? lowStockOnly}) {
    var result = _products.where((p) => p.isActive).toList();
    if (category != null && category != 'All') {
      result = result.where((p) => p.categoryName == category).toList();
    }
    if (lowStockOnly == true) {
      result = result.where((p) => p.isLowStock).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query) ||
            (p.barcode != null && p.barcode!.toLowerCase().contains(query));
      }).toList();
    }
    return result;
  }

  Future<void> loadProducts({bool reset = true}) async {
    if (reset) {
      if (_isLoading) return;
      _isLoading = true;
      _errorMessage = null;
      _hasMore = true;
      _products = [];
      _allProducts = [];
      notifyListeners();
    } else if (!_hasMore || _isLoading) {
      return;
    }

    try {
      // Run database operation on a background task to avoid blocking UI
      final maps = await Future.microtask(() async {
        return await _db.query(
          'products',
          where: 'is_deleted = 0',
          orderBy: 'name',
          limit: _pageSize,
        );
      });
      if (maps.isEmpty) {
        _hasMore = false;
      } else {
        final newProducts = maps.map((map) => Product.fromMap(map)).toList();
        if (reset) {
          _products = newProducts;
          _allProducts = newProducts;
        } else {
          _products.addAll(newProducts);
          _allProducts.addAll(newProducts);
        }
      }
      _loaded = true;
    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureLoaded() async {
    if (_loaded || _isLoading) return;
    await loadProducts();
  }

  Future<void> loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;
    await loadProducts(reset: false);
  }

  Future<bool> createProduct(Product product) async {
    try {
      final id = await _db.insert('products', product.toMap());
      final newProduct = Product(
        id: id,
        name: product.name,
        sku: product.sku,
        barcode: product.barcode,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        purchasePrice: product.purchasePrice,
        averageCost: product.averageCost,
        sellingPrice: product.sellingPrice,
        wholesalePrice: product.wholesalePrice,
        vipPrice: product.vipPrice,
        currentStock: product.currentStock,
        minimumStock: product.minimumStock,
        maximumStock: product.maximumStock,
        baseUnit: product.baseUnit,
        sellingUnit: product.sellingUnit,
        conversionFactor: product.conversionFactor,
        weightPerUnit: product.weightPerUnit,
        volumePerUnit: product.volumePerUnit,
        location: product.location,
        batchNumber: product.batchNumber,
        manufacturingDate: product.manufacturingDate,
        expiryDate: product.expiryDate,
        supplierId: product.supplierId,
        supplierName: product.supplierName,
        isActive: product.isActive,
        imagePath: product.imagePath,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );
      _products.insert(0, newProduct);
      _allProducts.insert(0, newProduct);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create product: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _db.update('products', product.toMap(), id: product.id!);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }
      final allIndex = _allProducts.indexWhere((p) => p.id == product.id);
      if (allIndex != -1) {
        _allProducts[allIndex] = product;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update product: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int productId) async {
    try {
      await _db.softDelete('products', id: productId);
      _products.removeWhere((p) => p.id == productId);
      _allProducts.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete product: $e';
      notifyListeners();
      return false;
    }
  }

  Product? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
