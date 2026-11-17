import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/database_service.dart';

class CustomerProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get _loaded => _customers.isNotEmpty;

  List<Customer> get activeCustomers =>
      _customers.where((c) => c.isActive).toList();

  List<Customer> get customersWithOutstandingBalance =>
      _customers.where((c) => c.currentBalance > 0).toList();

  List<Customer> filteredCustomers({String? searchQuery, bool? withBalance}) {
    var result = _customers.where((c) => c.isActive).toList();
    if (withBalance == true) {
      result = result.where((c) => c.currentBalance > 0).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((c) {
        return c.name.toLowerCase().contains(query) ||
            (c.phone?.toLowerCase().contains(query) ?? false) ||
            (c.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    return result;
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Run database operation on background task to avoid blocking UI
      final maps = await Future.microtask(() async {
        return await _db.query('customers', where: 'is_deleted = 0', orderBy: 'name');
      });
      _customers = maps.map((map) => Customer.fromMap(map)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load customers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureLoaded() async {
    if (!_loaded && !_isLoading) {
      await loadCustomers();
    }
  }

  Future<bool> createCustomer(Customer customer) async {
    try {
      final id = await _db.insert('customers', customer.toMap());
      final newCustomer = Customer(
        id: id,
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
        idNumber: customer.idNumber,
        creditLimit: customer.creditLimit,
        currentBalance: customer.currentBalance,
        notes: customer.notes,
        isActive: customer.isActive,
        createdAt: customer.createdAt,
        updatedAt: customer.updatedAt,
      );
      _customers.add(newCustomer);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create customer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      final updated = Customer(
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
        idNumber: customer.idNumber,
        creditLimit: customer.creditLimit,
        currentBalance: customer.currentBalance,
        notes: customer.notes,
        isActive: customer.isActive,
        createdAt: customer.createdAt,
        updatedAt: DateTime.now(),
      );
      await _db.update('customers', updated.toMap(), id: customer.id!);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update customer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(int customerId) async {
    try {
      await _db.softDelete('customers', id: customerId);
      _customers.removeWhere((c) => c.id == customerId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete customer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomerBalance(int customerId, double newBalance) async {
    try {
      final customer = _customers.firstWhere((c) => c.id == customerId);
      final updated = Customer(
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
        idNumber: customer.idNumber,
        creditLimit: customer.creditLimit,
        currentBalance: newBalance,
        notes: customer.notes,
        isActive: customer.isActive,
        createdAt: customer.createdAt,
        updatedAt: DateTime.now(),
      );
      await _db.update('customers', updated.toMap(), id: customerId);
      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _customers[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update customer balance: $e';
      notifyListeners();
      return false;
    }
  }

  Customer? getCustomerById(int id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
