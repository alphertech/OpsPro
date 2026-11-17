import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../providers/product_provider.dart';
import '../services/database_service.dart';

class ReportProvider {
  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(symbol: 'UGX', decimalDigits: 0);
    return formatter.format(value).replaceAll('UGX ', 'UGX');
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static double calculateTotalSales(List<Sale> sales) {
    return sales.fold(0, (sum, sale) => sum + sale.totalAmount.asDouble);
  }

  static double calculateTotalProfit(List<Sale> sales) {
    return sales.fold(0, (sum, sale) => sum + sale.items.fold(0, (itemSum, item) => itemSum + item.profit.asDouble));
  }

  static double calculateTotalExpenses(List<Expense> expenses) {
    return expenses.fold(0, (sum, expense) => sum + expense.amount.asDouble);
  }

  static double calculateNetProfit(List<Sale> sales, List<Expense> expenses) {
    return calculateTotalProfit(sales) - calculateTotalExpenses(expenses);
  }

  static int calculateTotalTransactions(List<Sale> sales) {
    return sales.length;
  }

  static double calculateAverageSaleValue(List<Sale> sales) {
    if (sales.isEmpty) return 0;
    return calculateTotalSales(sales) / sales.length;
  }

  static Map<String, double> getSalesByPaymentMethod(List<Sale> sales) {
    final Map<String, double> result = {};
    for (final sale in sales) {
      result[sale.paymentMethod] = (result[sale.paymentMethod] ?? 0) + sale.totalAmount.asDouble;
    }
    return result;
  }

  static Map<String, double> getSalesByDay(List<Sale> sales) {
    final Map<String, double> result = {};
    for (final sale in sales) {
      final day = DateFormat('dd MMM').format(sale.saleDate);
      result[day] = (result[day] ?? 0) + sale.totalAmount.asDouble;
    }
    return result;
  }

  static Map<String, double> getExpensesByCategory(List<Expense> expenses) {
    final Map<String, double> result = {};
    for (final expense in expenses) {
      result[expense.category] = (result[expense.category] ?? 0) + expense.amount.asDouble;
    }
    return result;
  }

  static List<MapEntry<String, double>> getTopSellingProducts(List<Sale> sales, {int limit = 10}) {
    final Map<String, double> productSales = {};
    for (final sale in sales) {
      for (final item in sale.items) {
        productSales[item.productName] = (productSales[item.productName] ?? 0) + item.totalAmount.asDouble;
      }
    }
    final sorted = productSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  static List<MapEntry<String, double>> getLowStockProducts(ProductProvider productProvider) {
    final lowStock = productProvider.lowStockProducts;
    return lowStock.map((p) => MapEntry(p.name, p.currentStock)).toList();
  }

  static double calculateTotalOutstandingBalance(List<Sale> sales) {
    return sales.fold(0, (sum, sale) => sum + sale.balanceDue.asDouble);
  }

  static int calculateCreditCustomers(List<Sale> sales) {
    final customerIds = <int>{};
    for (final sale in sales) {
      if (sale.isCredit && sale.customerId != null) {
        customerIds.add(sale.customerId!);
      }
    }
    return customerIds.length;
  }

  static double calculateTotalTaxCollected(List<Sale> sales) {
    return sales.fold(0, (sum, sale) => sum + sale.taxAmount.asDouble);
  }

  static double calculateTotalDiscountGiven(List<Sale> sales) {
    return sales.fold(0, (sum, sale) => sum + sale.discountAmount.asDouble);
  }

  static List<Sale> filterSalesByDateRange(List<Sale> sales, DateTime start, DateTime end) {
    return sales.where((sale) {
      return sale.saleDate.isAfter(start) || sale.saleDate.isAtSameMomentAs(start);
    }).where((sale) {
      return sale.saleDate.isBefore(end) || sale.saleDate.isAtSameMomentAs(end);
    }).toList();
  }

  static List<Sale> filterSalesByStatus(List<Sale> sales, String status) {
    return sales.where((sale) => sale.status == status).toList();
  }

  static List<Sale> filterSalesByPaymentMethod(List<Sale> sales, String paymentMethod) {
    return sales.where((sale) => sale.paymentMethod == paymentMethod).toList();
  }

  static Future<Map<String, dynamic>> getZReport({required DateTime date}) async {
    final db = DatabaseService();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final sales = await Future.microtask(() async {
      return await db.query(
        'sales',
        where: 'sale_date >= ? AND sale_date < ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
        orderBy: 'sale_date DESC',
      );
    });

    double totalSales = 0;
    double totalCash = 0;
    double totalCredit = 0;
    double totalMobileMoney = 0;
    double totalBank = 0;
    int transactionCount = 0;

    for (final saleMap in sales) {
      final status = saleMap['status'] as String? ?? 'Completed';
      if (status == 'Voided') continue;

      final totalAmount = (saleMap['total_amount'] as num?)?.toDouble() ?? 0;
      final paymentMethod = saleMap['payment_method'] as String? ?? '';

      totalSales += totalAmount;
      transactionCount++;

      final method = paymentMethod.toLowerCase();
      if (method == 'cash') {
        totalCash += totalAmount;
      } else if (method == 'credit') {
        totalCredit += totalAmount;
      } else if (method == 'mobile money') {
        totalMobileMoney += totalAmount;
      } else if (method == 'bank transfer') {
        totalBank += totalAmount;
      }
    }

    return {
      'date': startOfDay,
      'totalSales': totalSales,
      'totalCash': totalCash,
      'totalCredit': totalCredit,
      'totalMobileMoney': totalMobileMoney,
      'totalBank': totalBank,
      'transactionCount': transactionCount,
      'cashExpected': totalCash,
    };
  }

  static Future<Map<String, dynamic>?> getDailyClosing({required DateTime date}) async {
    final db = DatabaseService();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final closings = await Future.microtask(() async {
      return await db.query(
        'daily_closing',
        where: 'closing_date = ?',
        whereArgs: [startOfDay.toIso8601String()],
        limit: 1,
      );
    });
    if (closings.isEmpty) return null;
    return closings.first;
  }

  static Future<void> saveDailyClosing(Map<String, dynamic> closingData) async {
    final db = DatabaseService();
    await Future.microtask(() async {
      await db.insert('daily_closing', closingData);
    });
  }
}
