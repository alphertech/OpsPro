import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/purchase_order.dart';
import '../utils/money.dart';
import '../services/database_service.dart';

class PurchaseOrderProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<PurchaseOrder> _purchaseOrders = [];
  List<PurchaseOrderItem> _poItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PurchaseOrder> get purchaseOrders => _purchaseOrders;
  List<PurchaseOrderItem> get poItems => _poItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<PurchaseOrder> get draftPOs => _purchaseOrders.where((po) => po.status == 'Draft').toList();
  List<PurchaseOrder> get sentPOs => _purchaseOrders.where((po) => po.status == 'Sent').toList();
  List<PurchaseOrder> get partialPOs => _purchaseOrders.where((po) => po.status == 'Partial Receipt').toList();
  List<PurchaseOrder> get completedPOs => _purchaseOrders.where((po) => po.status == 'Completed').toList();

  Future<void> loadPurchaseOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final maps = await Future.microtask(() async {
        return await _db.query('purchase_orders', orderBy: 'order_date DESC');
      });
      _purchaseOrders = maps.map((map) => PurchaseOrder.fromMap(map)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load purchase orders: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPOItems(int poId) async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('purchase_order_items', where: 'po_id = ?', whereArgs: [poId]);
      });
      _poItems = maps.map((map) => PurchaseOrderItem.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load PO items: $e';
      notifyListeners();
    }
  }

  Future<bool> createPurchaseOrder(PurchaseOrder po, List<PurchaseOrderItem> items) async {
    try {
      final poId = await _db.insert('purchase_orders', po.toMap());

      for (final item in items) {
        await _db.insert('purchase_order_items', {
          ...item.toMap(),
          'po_id': poId,
        });
      }

      _purchaseOrders.insert(0, PurchaseOrder(
        id: poId,
        poNumber: po.poNumber,
        supplierId: po.supplierId,
        supplierName: po.supplierName,
        orderDate: po.orderDate,
        expectedDate: po.expectedDate,
        status: po.status,
        subtotal: po.subtotal,
        taxAmount: po.taxAmount,
        shippingCost: po.shippingCost,
        insuranceCost: po.insuranceCost,
        customsFee: po.customsFee,
        otherCosts: po.otherCosts,
        totalAmount: po.totalAmount,
        amountPaid: po.amountPaid,
        notes: po.notes,
        createdBy: po.createdBy,
        createdAt: po.createdAt,
        updatedAt: po.updatedAt,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create purchase order: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePurchaseOrder(PurchaseOrder po) async {
    try {
      await _db.update('purchase_orders', po.toMap(), id: po.id!);
      final index = _purchaseOrders.indexWhere((p) => p.id == po.id);
      if (index != -1) {
        _purchaseOrders[index] = po;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update purchase order: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePOStatus(int poId, String status) async {
    try {
      await _db.update('purchase_orders', {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: poId);

      final index = _purchaseOrders.indexWhere((p) => p.id == poId);
      if (index != -1) {
        _purchaseOrders[index] = _purchaseOrders[index].copyWith(status: status);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update PO status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> receiveItems(int poId, Map<int, double> receivedQuantities) async {
    try {
      for (final entry in receivedQuantities.entries) {
        final itemId = entry.key;
        final qty = entry.value;

        final itemMaps = await _db.query('purchase_order_items', where: 'id = ?', whereArgs: [itemId]);
        if (itemMaps.isNotEmpty) {
          final item = PurchaseOrderItem.fromMap(itemMaps.first);
          final newReceived = item.receivedQuantity + qty;

          await _db.update('purchase_order_items', {
            'received_quantity': newReceived,
          }, id: itemId);

          final productMap = await _db.queryOne('products', id: item.productId);
          if (productMap != null) {
            final currentStock = (productMap['current_stock'] as num?)?.toDouble() ?? 0.0;
            await _db.update('products', {
              'current_stock': currentStock + qty,
              'updated_at': DateTime.now().toIso8601String(),
            }, id: item.productId);
          }
        }
      }

      final poMaps = await _db.query('purchase_orders', where: 'id = ?', whereArgs: [poId]);
      if (poMaps.isNotEmpty) {
        final po = PurchaseOrder.fromMap(poMaps.first);
        final allItems = await _db.query('purchase_order_items', where: 'po_id = ?', whereArgs: [poId]);

        bool allReceived = true;
        bool anyReceived = false;

        for (final itemMap in allItems) {
          final item = PurchaseOrderItem.fromMap(itemMap);
          if (item.receivedQuantity > 0) anyReceived = true;
          if (item.receivedQuantity < item.quantity) allReceived = false;
        }

        String newStatus = po.status;
        if (allReceived) {
          newStatus = 'Completed';
        } else if (anyReceived) {
          newStatus = 'Partial Receipt';
        }

        await updatePOStatus(poId, newStatus);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to receive items: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordPayment(int poId, double amount) async {
    try {
      final poMaps = await _db.query('purchase_orders', where: 'id = ?', whereArgs: [poId]);
      if (poMaps.isNotEmpty) {
        final po = PurchaseOrder.fromMap(poMaps.first);
        final newAmountPaid = po.amountPaid + Money.fromDouble(amount);

        await _db.update('purchase_orders', {
          'amount_paid': newAmountPaid.asDouble,
          'updated_at': DateTime.now().toIso8601String(),
        }, id: poId);

        final index = _purchaseOrders.indexWhere((p) => p.id == poId);
        if (index != -1) {
          _purchaseOrders[index] = _purchaseOrders[index].copyWith(amountPaid: newAmountPaid);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to record payment: $e';
      notifyListeners();
      return false;
    }
  }

  PurchaseOrder? getPOById(int id) {
    try {
      return _purchaseOrders.firstWhere((po) => po.id == id);
    } catch (e) {
      return null;
    }
  }

  List<PurchaseOrder> getPOsForSupplier(int supplierId) {
    return _purchaseOrders.where((po) => po.supplierId == supplierId).toList();
  }

  Map<String, dynamic> getVendorPerformance(int supplierId) {
    final supplierPOs = getPOsForSupplier(supplierId);
    final completedPOs = supplierPOs.where((po) => po.status == 'Completed').toList();

    double avgLeadTime = 0;
    int onTimeDeliveries = 0;

    for (final po in completedPOs) {
      if (po.expectedDate != null) {
        final leadTime = po.orderDate.difference(po.expectedDate!).inDays.abs();
        avgLeadTime += leadTime;
      }
    }

    if (completedPOs.isNotEmpty) {
      avgLeadTime /= completedPOs.length;
    }

    return {
      'totalOrders': supplierPOs.length,
      'completedOrders': completedPOs.length,
      'avgLeadTime': avgLeadTime,
      'onTimeDeliveries': onTimeDeliveries,
    };
  }
}
