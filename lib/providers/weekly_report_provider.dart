import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/product.dart';
import '../utils/money.dart';
import '../providers/report_provider.dart';

class WeeklyReport {
  final String title;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> data;

  WeeklyReport({
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.data,
  });
}

class WeeklyReportProvider {
  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(symbol: 'UGX', decimalDigits: 0);
    return formatter.format(value).replaceAll('UGX ', 'UGX');
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static WeeklyReport generateBalanceSheet({
    required List<Sale> sales,
    required List<Expense> expenses,
    required List<Product> products,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final totalSales = ReportProvider.calculateTotalSales(sales);
    final totalExpenses = ReportProvider.calculateTotalExpenses(expenses);
    final totalOutstanding = ReportProvider.calculateTotalOutstandingBalance(sales);

    final inventoryValue = products.fold<double>(0, (sum, p) => sum + (p.currentStock * p.purchasePrice.asDouble));
    final cashInHand = totalSales - totalExpenses;

    final assets = <Map<String, dynamic>>[
      {'name': 'Cash in Hand', 'amount': cashInHand},
      {'name': 'Inventory Value', 'amount': inventoryValue},
      {'name': 'Accounts Receivable', 'amount': totalOutstanding},
    ];

    final liabilities = <Map<String, dynamic>>[
      {'name': 'Accounts Payable', 'amount': 0.0},
      {'name': 'Total Expenses', 'amount': totalExpenses},
    ];

    final totalAssets = assets.fold<double>(0, (sum, a) => sum + (a['amount'] as double));
    final totalLiabilities = liabilities.fold<double>(0, (sum, l) => sum + (l['amount'] as double));

    return WeeklyReport(
      title: 'Balance Sheet',
      type: 'balance_sheet',
      startDate: startDate,
      endDate: endDate,
      data: {
        'assets': assets,
        'liabilities': liabilities,
        'totalAssets': totalAssets,
        'totalLiabilities': totalLiabilities,
        'netWorth': totalAssets - totalLiabilities,
        'period': '${formatDate(startDate)} - ${formatDate(endDate)}',
      },
    );
  }

  static WeeklyReport generateQuotation({
    required List<Product> products,
    required DateTime generatedDate,
  }) {
    final items = products.map((p) {
      return {
        'name': p.name,
        'sku': p.sku,
        'unit': p.sellingUnit,
        'price': p.sellingPrice.asDouble,
        'wholesale': p.wholesalePrice.asDouble,
        'vip': p.vipPrice?.asDouble,
      };
    }).toList();

    return WeeklyReport(
      title: 'Price Quotation',
      type: 'quotation',
      startDate: generatedDate,
      endDate: generatedDate,
      data: {
        'items': items,
        'generatedDate': formatDate(generatedDate),
        'validUntil': formatDate(generatedDate.add(const Duration(days: 30))),
      },
    );
  }

  static WeeklyReport generateTransactionSheet({
    required List<Sale> sales,
    required List<Expense> expenses,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final transactions = <Map<String, dynamic>>[];

    for (final sale in sales) {
      transactions.add({
        'date': sale.saleDate,
        'type': 'Sale',
        'reference': sale.invoiceNumber,
        'description': '${sale.items.length} item(s) - ${sale.customerName ?? 'Walk-in'}',
        'amount': sale.totalAmount.asDouble,
        'paymentMethod': sale.paymentMethod,
        'status': sale.status,
      });
    }

    for (final expense in expenses) {
      transactions.add({
        'date': expense.expenseDate,
        'type': 'Expense',
        'reference': expense.reference ?? 'N/A',
        'description': '${expense.category} - ${expense.description ?? ''}',
        'amount': -expense.amount.asDouble,
        'paymentMethod': expense.paymentMethod ?? 'Cash',
        'status': 'Completed',
      });
    }

    transactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    final totalIn = transactions.where((t) => (t['amount'] as double) > 0).fold<double>(0, (sum, t) => sum + (t['amount'] as double));
    final totalOut = transactions.where((t) => (t['amount'] as double) < 0).fold<double>(0, (sum, t) => sum + (t['amount'] as double));

    return WeeklyReport(
      title: 'Transaction Sheet',
      type: 'transaction_sheet',
      startDate: startDate,
      endDate: endDate,
      data: {
        'transactions': transactions,
        'totalIn': totalIn,
        'totalOut': totalOut,
        'netFlow': totalIn + totalOut,
        'period': '${formatDate(startDate)} - ${formatDate(endDate)}',
        'totalTransactions': transactions.length,
      },
    );
  }

  static WeeklyReport generateTradeStatement({
    required List<Sale> sales,
    required List<Expense> expenses,
    required List<Product> products,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final totalSales = ReportProvider.calculateTotalSales(sales);
    final totalExpenses = ReportProvider.calculateTotalExpenses(expenses);
    final totalProfit = ReportProvider.calculateTotalProfit(sales);
    final netProfit = ReportProvider.calculateNetProfit(sales, expenses);
    final totalTax = ReportProvider.calculateTotalTaxCollected(sales);
    final totalDiscount = ReportProvider.calculateTotalDiscountGiven(sales);

    final costOfGoodsSold = sales.fold<double>(0, (sum, sale) {
      return sum + sale.items.fold<double>(0, (itemSum, item) => itemSum + Money.fromDouble(item.purchaseCost.asDouble * item.quantity).asDouble);
    });

    final topProducts = ReportProvider.getTopSellingProducts(sales, limit: 5);
    final salesByPayment = ReportProvider.getSalesByPaymentMethod(sales);
    final salesByDay = ReportProvider.getSalesByDay(sales);

    final dailyBreakdown = <Map<String, dynamic>>[];
    for (final entry in salesByDay.entries) {
      dailyBreakdown.add({
        'day': entry.key,
        'sales': entry.value,
        'percentage': totalSales > 0 ? (entry.value / totalSales) * 100 : 0,
      });
    }

    return WeeklyReport(
      title: 'Trade Statement',
      type: 'trade_statement',
      startDate: startDate,
      endDate: endDate,
      data: {
        'totalSales': totalSales,
        'costOfGoodsSold': costOfGoodsSold,
        'grossProfit': totalProfit,
        'totalExpenses': totalExpenses,
        'netProfit': netProfit,
        'totalTax': totalTax,
        'totalDiscount': totalDiscount,
        'totalTransactions': sales.length,
        'averageSaleValue': totalSales / (sales.isEmpty ? 1 : sales.length),
        'topProducts': topProducts,
        'salesByPayment': salesByPayment,
        'dailyBreakdown': dailyBreakdown,
        'period': '${formatDate(startDate)} - ${formatDate(endDate)}',
        'generatedDate': formatDate(DateTime.now()),
      },
    );
  }

  static WeeklyReport generateReport({
    required String type,
    required List<Sale> sales,
    required List<Expense> expenses,
    required List<Product> products,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    switch (type) {
      case 'balance_sheet':
        return generateBalanceSheet(
          sales: sales,
          expenses: expenses,
          products: products,
          startDate: startDate,
          endDate: endDate,
        );
      case 'quotation':
        return generateQuotation(
          products: products,
          generatedDate: DateTime.now(),
        );
      case 'transaction_sheet':
        return generateTransactionSheet(
          sales: sales,
          expenses: expenses,
          startDate: startDate,
          endDate: endDate,
        );
      case 'trade_statement':
        return generateTradeStatement(
          sales: sales,
          expenses: expenses,
          products: products,
          startDate: startDate,
          endDate: endDate,
        );
      default:
        throw ArgumentError('Unknown report type: $type');
    }
  }
}
