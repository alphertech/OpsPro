import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../services/database_service.dart';

class SaleProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Sale> _todaySales = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Sale> get todaySales => _todaySales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTodaySales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      // Run database operations on background task to avoid blocking UI
      final saleMaps = await Future.microtask(() async {
        return await _db.query(
          'sales',
          where: 'sale_date >= ? AND is_deleted = 0',
          whereArgs: [startOfDay.toIso8601String()],
          orderBy: 'sale_date DESC',
        );
      });

      final saleIds = saleMaps.map((m) => m['id'] as int).toList();
      final itemMapsBySaleId = <int, List<Map<String, dynamic>>>{};
      if (saleIds.isNotEmpty) {
        final placeholders = List.filled(saleIds.length, '?').join(',');
        final allItemMaps = await Future.microtask(() async {
          return await _db.query(
            'sale_items',
            where: 'sale_id IN ($placeholders)',
            whereArgs: saleIds,
            orderBy: 'sale_id, id',
          );
        });
        for (final itemMap in allItemMaps) {
          final saleId = itemMap['sale_id'] as int;
          itemMapsBySaleId.putIfAbsent(saleId, () => []).add(itemMap);
        }
      }

      _todaySales = saleMaps.map((saleMap) {
        final sale = Sale.fromMap(saleMap);
        final itemMaps = itemMapsBySaleId[sale.id!] ?? [];
        final items = itemMaps.map((itemMap) => SaleItem.fromMap(itemMap)).toList();
        return sale.copyWithItems(items);
      }).toList();
    } catch (e) {
      _errorMessage = 'Failed to load sales: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureLoaded() async {
    if (_todaySales.isEmpty && !_isLoading) {
      await loadTodaySales();
    }
  }

  /// Loads all sales (with their items) within an inclusive date range.
  /// Unlike [loadTodaySales] this honours the selected report period, so
  /// weekly/monthly reports actually contain the chosen transactions.
  Future<List<Sale>> loadSalesByDateRange(DateTime start, DateTime end) async {
    final saleMaps = await Future.microtask(() async {
      return await _db.query(
        'sales',
        where: 'sale_date >= ? AND sale_date <= ? AND is_deleted = 0',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'sale_date DESC',
      );
    });

    final saleIds = saleMaps.map((m) => m['id'] as int).toList();
    final itemMapsBySaleId = <int, List<Map<String, dynamic>>>{};
    if (saleIds.isNotEmpty) {
      final placeholders = List.filled(saleIds.length, '?').join(',');
      final allItemMaps = await Future.microtask(() async {
        return await _db.query(
          'sale_items',
          where: 'sale_id IN ($placeholders)',
          whereArgs: saleIds,
          orderBy: 'sale_id, id',
        );
      });
      for (final itemMap in allItemMaps) {
        final saleId = itemMap['sale_id'] as int;
        itemMapsBySaleId.putIfAbsent(saleId, () => []).add(itemMap);
      }
    }

    return saleMaps.map((saleMap) {
      final sale = Sale.fromMap(saleMap);
      final itemMaps = itemMapsBySaleId[sale.id!] ?? [];
      final items = itemMaps.map((itemMap) => SaleItem.fromMap(itemMap)).toList();
      return sale.copyWithItems(items);
    }).toList();
  }

  Future<Sale?> createSale(Sale sale) async {
    try {
    await _db.transaction((db) async {
      final id = await db.insert('sales', sale.toMap());
        for (final item in sale.items) {
          final itemMap = item.toMap();
          itemMap['sale_id'] = id;
          await db.insert('sale_items', itemMap);
        }
        final productIds = sale.items.map((i) => i.productId).toList();
        final placeholders = List.filled(productIds.length, '?').join(',');
        final productRows = await db.query(
          'products',
          where: 'id IN ($placeholders)',
          whereArgs: productIds,
        );
        final productMap = {for (var r in productRows) r['id'] as int: r};
        for (final item in sale.items) {
          final row = productMap[item.productId];
          if (row != null) {
            final currentStock = (row['current_stock'] as num?)?.toDouble() ?? 0.0;
            final newStock = currentStock - item.quantity;
            await db.update('products', {
              'current_stock': newStock > 0 ? newStock : 0,
              'updated_at': DateTime.now().toIso8601String(),
            }, where: 'id = ?', whereArgs: [item.productId]);
          }
        }
        await db.insert('transaction_log', {
          'table_name': 'sales',
          'record_id': id,
          'action': 'CREATE',
          'old_values': null,
          'new_values': sale.toMap().toString(),
          'user_id': sale.userId,
          'user_name': sale.userName,
          'created_at': DateTime.now().toIso8601String(),
        });
        await db.insert('cash_movements', {
          'movement_type': 'sale',
          'amount': sale.totalAmount.asDouble,
          'payment_method': sale.paymentMethod,
          'sale_id': id,
          'reference': sale.paymentReference,
          'notes': sale.notes,
          'user_id': sale.userId,
          'user_name': sale.userName,
          'created_at': DateTime.now().toIso8601String(),
        });
        return id;
      });
      final createdSale = sale.copyWithItems(sale.items);
      _todaySales.insert(0, createdSale);
      notifyListeners();
      return createdSale;
    } catch (e) {
      _errorMessage = 'Failed to create sale: $e';
      notifyListeners();
      return null;
    }
  }

  Future<Sale?> voidSale(int saleId) async {
    try {
      final saleMap = await _db.queryOne('sales', id: saleId);
      if (saleMap == null) return null;
      final sale = Sale.fromMap(saleMap);
      final voidedSale = Sale(
        id: sale.id,
        invoiceNumber: sale.invoiceNumber,
        saleDate: sale.saleDate,
        customerId: sale.customerId,
        customerName: sale.customerName,
        userId: sale.userId,
        userName: sale.userName,
        subtotal: sale.subtotal,
        discountAmount: sale.discountAmount,
        taxAmount: sale.taxAmount,
        totalAmount: sale.totalAmount,
        amountPaid: sale.amountPaid,
        balanceDue: sale.balanceDue,
        paymentMethod: sale.paymentMethod,
        paymentReference: sale.paymentReference,
        status: 'Voided',
        notes: sale.notes,
        isCredit: sale.isCredit,
        dueDate: sale.dueDate,
        items: sale.items,
        createdAt: sale.createdAt,
        updatedAt: DateTime.now(),
      );
      await _db.transaction((db) async {
        await db.update('sales', voidedSale.toMap(), where: 'id = ?', whereArgs: [saleId]);
        final productIds = sale.items.map((i) => i.productId).toList();
        final placeholders = List.filled(productIds.length, '?').join(',');
        final productRows = await db.query(
          'products',
          where: 'id IN ($placeholders)',
          whereArgs: productIds,
        );
        final productMap = {for (var r in productRows) r['id'] as int: r};
        for (final item in sale.items) {
          final row = productMap[item.productId];
          if (row != null) {
            final currentStock = (row['current_stock'] as num?)?.toDouble() ?? 0.0;
            final newStock = currentStock + item.quantity;
            await db.update('products', {
              'current_stock': newStock,
              'updated_at': DateTime.now().toIso8601String(),
            }, where: 'id = ?', whereArgs: [item.productId]);
          }
        }
        await db.insert('transaction_log', {
          'table_name': 'sales',
          'record_id': saleId,
          'action': 'VOID',
          'old_values': saleMap.toString(),
          'new_values': voidedSale.toMap().toString(),
          'user_id': sale.userId,
          'user_name': sale.userName,
          'created_at': DateTime.now().toIso8601String(),
        });
        await db.insert('cash_movements', {
          'movement_type': 'void',
          'amount': sale.totalAmount.asDouble,
          'payment_method': sale.paymentMethod,
          'sale_id': saleId,
          'reference': sale.paymentReference,
          'notes': 'Voided sale',
          'user_id': sale.userId,
          'user_name': sale.userName,
          'created_at': DateTime.now().toIso8601String(),
        });
      });
      notifyListeners();
      return voidedSale;
    } catch (e) {
      _errorMessage = 'Failed to void sale: $e';
      notifyListeners();
      return null;
    }
  }
}
