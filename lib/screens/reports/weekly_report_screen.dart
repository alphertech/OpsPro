import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/weekly_report_provider.dart';
import '../../providers/weekly_report_pdf_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/custom_app_bar.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _selectedReportType = 'balance_sheet';
  WeeklyReport? _generatedReport;
  bool _isGenerating = false;

  final List<Map<String, dynamic>> _reportTypes = [
    {'id': 'balance_sheet', 'title': 'Balance Sheet', 'icon': CupertinoIcons.doc_text, 'color': Colors.blue, 'description': 'Assets, liabilities & net worth'},
    {'id': 'quotation', 'title': 'Price Quotation', 'icon': CupertinoIcons.tag, 'color': Colors.green, 'description': 'Product price list'},
    {'id': 'transaction_sheet', 'title': 'Transaction Sheet', 'icon': CupertinoIcons.list_bullet, 'color': Colors.orange, 'description': 'Daily transaction log'},
    {'id': 'trade_statement', 'title': 'Trade Statement', 'icon': CupertinoIcons.chart_bar, 'color': Colors.purple, 'description': 'Sales, expenses & profit summary'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Weekly Reports', showBackButton: true),
      drawer: const AppDrawer(currentRoute: '/reports'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateSelector(),
            const SizedBox(height: 16),
            _buildReportTypeGrid(),
            const SizedBox(height: 16),
            _buildGenerateButton(),
            const SizedBox(height: 16),
            if (_generatedReport != null) _buildReportPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, isStart: true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.calendar_today, size: 16, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          Text(DateFormat('dd MMM yyyy').format(_startDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, isStart: false),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.calendar, size: 16, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('To', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          Text(DateFormat('dd MMM yyyy').format(_endDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeGrid() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Report Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: _reportTypes.map((report) {
                final isSelected = _selectedReportType == report['id'];
                return InkWell(
                  onTap: () => setState(() => _selectedReportType = report['id']),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? (report['color'] as Color).withValues(alpha: 0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? report['color'] : Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(report['icon'], color: report['color'], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(report['title'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? report['color'] : null)),
                              Text(report['description'], style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        label: _isGenerating ? 'Generating...' : 'Generate Report',
        icon: CupertinoIcons.doc_text,
        isLoading: _isGenerating,
        onPressed: _isGenerating ? null : _generateReport,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildReportPreview() {
    final report = _generatedReport!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(report.title, style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _downloadPdf(report),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('PDF', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: () => _printReport(report),
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Print', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: () => _shareReport(report),
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Period: ${report.data['period']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ..._buildReportContent(report),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReportContent(WeeklyReport report) {
    switch (report.type) {
      case 'balance_sheet':
        return _buildBalanceSheetContent(report);
      case 'quotation':
        return _buildQuotationContent(report);
      case 'transaction_sheet':
        return _buildTransactionSheetContent(report);
      case 'trade_statement':
        return _buildTradeStatementContent(report);
      default:
        return [const Text('Unknown report type')];
    }
  }

  List<Widget> _buildBalanceSheetContent(WeeklyReport report) {
    final data = report.data;
    return [
      _buildSectionTitle('Assets'),
      ...data['assets'].map<Widget>((asset) => _buildSummaryRow(asset['name'], WeeklyReportProvider.formatCurrency(asset['amount']))).toList(),
      _buildSummaryRow('Total Assets', WeeklyReportProvider.formatCurrency(data['totalAssets']), isBold: true),
      const SizedBox(height: 12),
      _buildSectionTitle('Liabilities'),
      ...data['liabilities'].map<Widget>((liability) => _buildSummaryRow(liability['name'], WeeklyReportProvider.formatCurrency(liability['amount']))).toList(),
      _buildSummaryRow('Total Liabilities', WeeklyReportProvider.formatCurrency(data['totalLiabilities']), isBold: true),
      const SizedBox(height: 12),
      _buildSummaryRow('Net Worth', WeeklyReportProvider.formatCurrency(data['netWorth']), isBold: true, valueColor: Colors.green),
    ];
  }

  List<Widget> _buildQuotationContent(WeeklyReport report) {
    final data = report.data;
    final items = data['items'] as List;
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Generated: ${data['generatedDate']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text('Valid until: ${data['validUntil']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Divider(),
      ...items.map<Widget>((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    Text('SKU: ${item['sku']} | Unit: ${item['unit']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(WeeklyReportProvider.formatCurrency(item['price']), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('W: ${WeeklyReportProvider.formatCurrency(item['wholesale'])} | V: ${WeeklyReportProvider.formatCurrency(item['vip'])}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        );
      }),
    ];
  }

  List<Widget> _buildTransactionSheetContent(WeeklyReport report) {
    final data = report.data;
    final transactions = data['transactions'] as List;
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryRow('Total In', WeeklyReportProvider.formatCurrency(data['totalIn']), valueColor: Colors.green),
          _buildSummaryRow('Total Out', WeeklyReportProvider.formatCurrency(data['totalOut'].abs()), valueColor: Colors.red),
          _buildSummaryRow('Net Flow', WeeklyReportProvider.formatCurrency(data['netFlow']), isBold: true),
        ],
      ),
      const SizedBox(height: 12),
      const Divider(),
      ...transactions.map((tx) {
        final date = tx['date'] as DateTime;
        final isIn = (tx['amount'] as double) > 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isIn ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx['type'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('${tx['reference']} - ${tx['description']}', style: TextStyle(fontSize: 10, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${isIn ? '+' : ''}${WeeklyReportProvider.formatCurrency(tx['amount'])}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isIn ? Colors.green : Colors.red)),
                  Text(DateFormat('dd MMM').format(date), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        );
      }),
    ];
  }

  List<Widget> _buildTradeStatementContent(WeeklyReport report) {
    final data = report.data;
    return [
      Row(
        children: [
          Expanded(child: _buildSummaryCard('Total Sales', WeeklyReportProvider.formatCurrency(data['totalSales']), Colors.green)),
          const SizedBox(width: 10),
          Expanded(child: _buildSummaryCard('Net Profit', WeeklyReportProvider.formatCurrency(data['netProfit']), Colors.purple)),
        ],
      ),
      const SizedBox(height: 12),
      _buildSectionTitle('Financial Breakdown'),
      _buildSummaryRow('Gross Profit', WeeklyReportProvider.formatCurrency(data['grossProfit'])),
      _buildSummaryRow('Cost of Goods Sold', WeeklyReportProvider.formatCurrency(data['costOfGoodsSold'])),
      _buildSummaryRow('Total Expenses', WeeklyReportProvider.formatCurrency(data['totalExpenses'])),
      _buildSummaryRow('Tax Collected', WeeklyReportProvider.formatCurrency(data['totalTax'])),
      _buildSummaryRow('Discounts Given', WeeklyReportProvider.formatCurrency(data['totalDiscount'])),
      _buildSummaryRow('Transactions', '${data['totalTransactions']}'),
      _buildSummaryRow('Avg. Sale Value', WeeklyReportProvider.formatCurrency(data['averageSaleValue'])),
      const SizedBox(height: 12),
      _buildSectionTitle('Top Products'),
      ...data['topProducts'].take(5).map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry['key'], style: const TextStyle(fontSize: 13)),
              Text(WeeklyReportProvider.formatCurrency(entry['value']), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
        );
      }),
      const SizedBox(height: 12),
      _buildSectionTitle('Sales by Payment'),
      ...data['salesByPayment'].entries.map((entry) {
        return _buildSummaryRow(entry.key, WeeklyReportProvider.formatCurrency(entry.value));
      }),
    ];
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[700], letterSpacing: 0.5)),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _generatedReport = null;
    });

    try {
      final saleProvider = context.read<SaleProvider>();
      final expenseProvider = context.read<ExpenseProvider>();
      final productProvider = context.read<ProductProvider>();

      final sales = await saleProvider.loadSalesByDateRange(_startDate, _endDate);
      await expenseProvider.loadExpenses();
      await productProvider.loadProducts();

      final expenses = expenseProvider.filteredExpenses(startDate: _startDate, endDate: _endDate);

      final report = WeeklyReportProvider.generateReport(
        type: _selectedReportType,
        sales: sales,
        expenses: expenses,
        products: productProvider.products,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _generatedReport = report;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate report: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<Uint8List> _buildPdfBytes(WeeklyReport report) async {
    final saleProvider = context.read<SaleProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final productProvider = context.read<ProductProvider>();

    await expenseProvider.loadExpenses();
    await productProvider.loadProducts();

    final sales = await saleProvider.loadSalesByDateRange(_startDate, _endDate);
    final expenses = expenseProvider.filteredExpenses(startDate: _startDate, endDate: _endDate);

    return WeeklyReportPdfProvider.generatePdfBytes(report, sales, expenses, productProvider.products);
  }

  String _pdfFileName(WeeklyReport report) {
    return '${report.title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
  }

  Future<void> _downloadPdf(WeeklyReport report) async {
    setState(() => _isGenerating = true);

    try {
      final bytes = await _buildPdfBytes(report);
      final fileName = _pdfFileName(report);

      final String? selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ${report.title} as PDF',
        fileName: fileName,
      );

      if (selectedPath == null) {
        // User cancelled the save dialog.
        if (mounted) setState(() => _isGenerating = false);
        return;
      }

      final path = selectedPath.endsWith('.pdf') ? selectedPath : '$selectedPath.pdf';
      await File(path).writeAsBytes(bytes);

      setState(() => _isGenerating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $path'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printReport(WeeklyReport report) async {
    try {
      await Printing.layoutPdf(
        name: report.title,
        onLayout: (_) => _buildPdfBytes(report),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareReport(WeeklyReport report) async {
    setState(() => _isGenerating = true);
    try {
      final bytes = await _buildPdfBytes(report);
      await Printing.sharePdf(bytes: bytes, filename: _pdfFileName(report));

      setState(() => _isGenerating = false);
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
