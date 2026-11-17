import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../services/database_service.dart';

class SupplierProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _loaded = false;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSuppliers() async {
    if (_loaded && _suppliers.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final maps = await Future.microtask(() async {
        return await _db.query('suppliers', where: 'is_deleted = 0', orderBy: 'name');
      });
      _suppliers = maps.map((map) => Supplier.fromMap(map)).toList();
      _loaded = true;
    } catch (e) {
      _errorMessage = 'Failed to load suppliers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureLoaded() async {
    if (!_loaded && !_isLoading) {
      await loadSuppliers();
    }
  }

  Future<bool> createSupplier(Supplier supplier) async {
    try {
      final id = await _db.insert('suppliers', supplier.toMap());
      final newSupplier = Supplier(
        id: id,
        name: supplier.name,
        contactPerson: supplier.contactPerson,
        phone: supplier.phone,
        email: supplier.email,
        address: supplier.address,
        createdAt: supplier.createdAt,
        updatedAt: supplier.updatedAt,
      );
      _suppliers.add(newSupplier);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create supplier: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      final updatedSupplier = supplier.copyWith(updatedAt: DateTime.now());
      await _db.update('suppliers', updatedSupplier.toMap(), id: supplier.id!);
      final index = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (index != -1) {
        _suppliers[index] = updatedSupplier;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update supplier: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSupplier(int supplierId) async {
    try {
      await _db.softDelete('suppliers', id: supplierId);
      _suppliers.removeWhere((s) => s.id == supplierId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete supplier: $e';
      notifyListeners();
      return false;
    }
  }

  Supplier? getSupplierById(int id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}
