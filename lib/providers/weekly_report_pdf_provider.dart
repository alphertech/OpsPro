import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/product.dart';
import 'weekly_report_provider.dart';

class WeeklyReportPdfProvider {
  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(symbol: 'UGX', decimalDigits: 0);
    return formatter.format(value).replaceAll('UGX ', 'UGX');
  }

  static pw.Document _buildDocument(WeeklyReport report) {
    final pdf = pw.Document();
    final now = DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());

    pw.Widget buildHeader() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(report.title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Period: ${report.data['period']}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text('Generated: $now', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Divider(),
        ],
      );
    }

    pw.Widget buildFooter() {
      return pw.Container(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Plexus', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
            pw.Text('Page ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
          ],
        ),
      );
    }

    switch (report.type) {
      case 'balance_sheet':
        pdf.addPage(
          pw.Page(
            margin: const pw.EdgeInsets.all(24),
            build: (context) {
              final data = report.data;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildHeader(),
                  pw.Text('Assets', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ...data['assets'].map<pw.Widget>((asset) {
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(asset['name'], style: const pw.TextStyle(fontSize: 11)),
                        pw.Text(formatCurrency(asset['amount']), style: const pw.TextStyle(fontSize: 11)),
                      ],
                    );
                  }).toList(),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Assets', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text(formatCurrency(data['totalAssets']), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text('Liabilities', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ...data['liabilities'].map<pw.Widget>((liability) {
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(liability['name'], style: const pw.TextStyle(fontSize: 11)),
                        pw.Text(formatCurrency(liability['amount']), style: const pw.TextStyle(fontSize: 11)),
                      ],
                    );
                  }).toList(),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Liabilities', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text(formatCurrency(data['totalLiabilities']), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Net Worth', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      pw.Text(formatCurrency(data['netWorth']), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                    ],
                  ),
                  buildFooter(),
                ],
              );
            },
          ),
        );
      case 'quotation':
        pdf.addPage(
          pw.Page(
            margin: const pw.EdgeInsets.all(24),
            build: (context) {
              final data = report.data;
              final items = data['items'] as List;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildHeader(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Generated: ${data['generatedDate']}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      pw.Text('Valid until: ${data['validUntil']}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2),
                      1: pw.FlexColumnWidth(1),
                      2: pw.FlexColumnWidth(1),
                      3: pw.FlexColumnWidth(1),
                      4: pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Product', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('SKU', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Unit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Selling', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Wholesale', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        ],
                      ),
                      ...items.map<pw.TableRow>((item) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item['name'], style: const pw.TextStyle(fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item['sku'], style: const pw.TextStyle(fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item['unit'], style: const pw.TextStyle(fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(formatCurrency(item['price']), style: const pw.TextStyle(fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(formatCurrency(item['wholesale']), style: const pw.TextStyle(fontSize: 10))),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text('VIP prices available on request', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
                  buildFooter(),
                ],
              );
            },
          ),
        );
      case 'transaction_sheet':
        pdf.addPage(
          pw.Page(
            margin: const pw.EdgeInsets.all(24),
            build: (context) {
              final data = report.data;
              final transactions = data['transactions'] as List;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildHeader(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total In', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                          pw.Text(formatCurrency(data['totalIn']), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Out', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                          pw.Text(formatCurrency(data['totalOut'].abs()), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Net Flow', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                          pw.Text(formatCurrency(data['netFlow']), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1),
                      1: pw.FlexColumnWidth(1),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(1),
                      4: pw.FlexColumnWidth(1),
                      5: pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Method', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        ],
                      ),
                      ...transactions.map<pw.TableRow>((tx) {
                        final date = tx['date'] as DateTime;
                        final isIn = (tx['amount'] as double) > 0;
                        return pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateFormat('dd MMM').format(date), style: const pw.TextStyle(fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(tx['type'], style: const pw.TextStyle(fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${tx['reference']} - ${tx['description']}', style: const pw.TextStyle(fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${isIn ? '+' : ''}${formatCurrency(tx['amount'])}', style: pw.TextStyle(fontSize: 10, color: isIn ? PdfColors.green700 : PdfColors.red700))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(tx['paymentMethod'], style: const pw.TextStyle(fontSize: 10))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(tx['status'], style: const pw.TextStyle(fontSize: 10))),
                          ],
                        );
                      }),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text('Total Transactions: ${data['totalTransactions']}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  buildFooter(),
                ],
              );
            },
          ),
        );
      case 'trade_statement':
        pdf.addPage(
          pw.Page(
            margin: const pw.EdgeInsets.all(24),
            build: (context) {
              final data = report.data;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildHeader(),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: const pw.BoxDecoration(color: PdfColors.green100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Total Sales', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                              pw.Text(formatCurrency(data['totalSales']), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: const pw.BoxDecoration(color: PdfColors.purple100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Net Profit', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                              pw.Text(formatCurrency(data['netProfit']), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.purple800)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text('Financial Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ...['Gross Profit', 'Cost of Goods Sold', 'Total Expenses', 'Tax Collected', 'Discounts Given', 'Transactions', 'Avg. Sale Value'].asMap().entries.map((entry) {
                    final keys = ['grossProfit', 'costOfGoodsSold', 'totalExpenses', 'totalTax', 'totalDiscount', 'totalTransactions', 'averageSaleValue'];
                    final isBold = entry.key >= 5;
                    final value = data[keys[entry.key]];
                    final displayValue = keys[entry.key] == 'totalTransactions' ? '$value' : formatCurrency(value);
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(entry.value, style: pw.TextStyle(fontSize: 11, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
                        pw.Text(displayValue, style: pw.TextStyle(fontSize: 11, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
                      ],
                    );
                  }),
                  pw.SizedBox(height: 16),
                  pw.Text('Top Products', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ...data['topProducts'].take(5).map<pw.Widget>((entry) {
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(entry['key'], style: const pw.TextStyle(fontSize: 11)),
                        pw.Text(formatCurrency(entry['value']), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ],
                    );
                  }).toList(),
                  pw.SizedBox(height: 16),
                  pw.Text('Sales by Payment Method', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ...data['salesByPayment'].entries.map<pw.Widget>((entry) {
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(entry.key, style: const pw.TextStyle(fontSize: 11)),
                        pw.Text(formatCurrency(entry.value), style: const pw.TextStyle(fontSize: 11)),
                      ],
                    );
                  }).toList(),
                  buildFooter(),
                ],
              );
            },
          ),
        );
      default:
        pdf.addPage(
          pw.Page(
            margin: const pw.EdgeInsets.all(24),
            build: (context) => pw.Center(child: pw.Text('Report type not supported for PDF export')),
          ),
        );
    }

    return pdf;
  }

  static Future<Uint8List> generatePdfBytes(WeeklyReport report, List<Sale> sales, List<Expense> expenses, List<Product> products) async {
    final pdf = _buildDocument(report);
    return pdf.save();
  }

  static Future<File> generatePdf(WeeklyReport report, List<Sale> sales, List<Expense> expenses, List<Product> products) async {
    final pdf = _buildDocument(report);
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${report.title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
