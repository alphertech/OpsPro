import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/report_provider.dart';
import '../providers/security_provider.dart';
import '../config/app_theme.dart';
import '../config/routes.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/app_drawer.dart';

class ZReportScreen extends StatefulWidget {
  const ZReportScreen({super.key});

  @override
  State<ZReportScreen> createState() => _ZReportScreenState();
}

class _ZReportScreenState extends State<ZReportScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  Map<String, dynamic>? _existingClosing;
  final TextEditingController _cashCountController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _cashCountController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final report = await ReportProvider.getZReport(date: _selectedDate);
      final closing = await ReportProvider.getDailyClosing(date: _selectedDate);

      setState(() {
        _reportData = report;
        _existingClosing = closing;
        _isLoading = false;
        if (closing != null) {
          _cashCountController.text = (closing['cash_counted'] as num?)?.toDouble().toStringAsFixed(0) ?? '';
        } else {
          _cashCountController.clear();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load Z-Report: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _cashCountController.clear();
      });
      _loadReport();
    }
  }

  Future<void> _finalizeDay() async {
    final cashCounted = double.tryParse(_cashCountController.text.trim());
    if (cashCounted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the physical cash count')),
      );
      return;
    }

    if (_reportData == null) return;

    final cashExpected = _reportData!['cashExpected'] as double;
    final variance = cashExpected - cashCounted;

    final security = context.read<SecurityProvider>();
    final user = security.currentUser;

    final closingData = {
      'closing_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'cash_expected': cashExpected,
      'cash_counted': cashCounted,
      'cash_variance': variance,
      'total_sales': _reportData!['totalSales'],
      'total_cash': _reportData!['totalCash'],
      'total_credit': _reportData!['totalCredit'],
      'total_mobile': _reportData!['totalMobileMoney'],
      'total_bank': _reportData!['totalBank'],
      'transaction_count': _reportData!['transactionCount'],
      'snapshot_json': jsonEncode(_reportData!),
      'user_id': user?.id,
      'user_name': user?.displayName,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await ReportProvider.saveDailyClosing(closingData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Day closed successfully. Shutting down...')),
        );
        await security.logout();
        await Future.delayed(const Duration(seconds: 2));
        try {
          await windowManager.destroy();
        } catch (_) {
          exit(0);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to close day: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Z-Report / Close Day', showBackButton: true),
      drawer: const AppDrawer(currentRoute: AppRoutes.zReport),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildReportContent(),
    );
  }

  Widget _buildReportContent() {
    final isReadOnly = _existingClosing != null;
    final report = _reportData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: ListTile(
              title: const Text('Report Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
              trailing: IconButton(
                icon: const Icon(CupertinoIcons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sales Summary', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Total Sales', AppTheme.formatCurrency(report?['totalSales'] ?? 0)),
                  _buildSummaryRow('Cash Sales', AppTheme.formatCurrency(report?['totalCash'] ?? 0)),
                  _buildSummaryRow('Credit Sales', AppTheme.formatCurrency(report?['totalCredit'] ?? 0)),
                  _buildSummaryRow('Mobile Money', AppTheme.formatCurrency(report?['totalMobileMoney'] ?? 0)),
                  _buildSummaryRow('Bank Transfer', AppTheme.formatCurrency(report?['totalBank'] ?? 0)),
                  const Divider(),
                  _buildSummaryRow('Transactions', '${report?['transactionCount'] ?? 0}', isBold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cash Reconciliation', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Cash Expected', AppTheme.formatCurrency(report?['cashExpected'] ?? 0)),
                  const SizedBox(height: 12),
                  if (isReadOnly) ...[
                    _buildSummaryRow('Cash Counted', AppTheme.formatCurrency(_existingClosing?['cash_counted'] ?? 0)),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Variance',
                      AppTheme.formatCurrency(_existingClosing?['cash_variance'] ?? 0),
                      valueColor: (_existingClosing?['cash_variance'] ?? 0) >= 0 ? Colors.red : Colors.green,
                    ),
                  ] else ...[
                    TextField(
                      controller: _cashCountController,
                      decoration: const InputDecoration(
                        labelText: 'Physical Cash Counted',
                        prefixText: 'UGX ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !isReadOnly,
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    if (_cashCountController.text.isNotEmpty)
                      _buildSummaryRow(
                        'Variance',
                        AppTheme.formatCurrency((report?['cashExpected'] ?? 0) - (double.tryParse(_cashCountController.text) ?? 0)),
                        valueColor: ((report?['cashExpected'] ?? 0) - (double.tryParse(_cashCountController.text) ?? 0)) >= 0 ? Colors.red : Colors.green,
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!isReadOnly)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _finalizeDay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close Day / Finalize'),
              ),
            )
          else
            Card(
              color: Colors.green.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Day Closed', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
                          Text('Closed by ${_existingClosing?['user_name'] ?? 'Unknown'}', style: TextStyle(color: Colors.green[700], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
