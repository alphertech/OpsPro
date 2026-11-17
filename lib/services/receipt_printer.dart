import 'dart:async';
import 'package:esc_pos_printer_lts/esc_pos_printer_lts.dart';
import 'package:esc_pos_utils_lts/esc_pos_utils_lts.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../config/app_theme.dart';
import '../utils/money.dart';

class ReceiptPrinter {
  static const String defaultPrinterIp = '192.168.1.100';
  static const int defaultPort = 9100;
  static const Duration connectTimeout = Duration(seconds: 5);

  static Future<bool> printReceipt(
    Sale sale, {
    required String printerIp,
    int port = defaultPort,
    PaperSize paperSize = PaperSize.mm80,
  }) async {
    NetworkPrinter? printer;
    try {
      final profile = await CapabilityProfile.load();
      printer = NetworkPrinter(paperSize, profile);

      final PosPrintResult connectResult = await printer.connect(
        printerIp,
        port: port,
        timeout: connectTimeout,
      );

      if (connectResult != PosPrintResult.success) {
        return false;
      }

      final List<int> ticket = _buildTicket(sale, paperSize, profile);
      printer.rawBytes(ticket);
      return true;
    } catch (e) {
      return false;
    } finally {
      try {
        printer?.disconnect();
      } catch (_) {}
    }
  }

  static List<int> _buildTicket(
    Sale sale,
    PaperSize paperSize,
    CapabilityProfile profile,
  ) {
    final generator = Generator(paperSize, profile);
    List<int> bytes = <int>[];

    final String dateStr =
        DateFormat('dd MMM yyyy HH:mm').format(sale.saleDate);

    bytes += generator.text(
      'Plexus',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      'Business Management System',
      styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size1),
    );
    bytes += generator.hr();
    bytes += generator.text('Invoice: ${sale.invoiceNumber}');
    bytes += generator.text('Date: $dateStr');
    if (sale.customerName != null && sale.customerName!.isNotEmpty) {
      bytes += generator.text('Customer: ${sale.customerName}');
    }
    bytes += generator.hr();

    bytes += generator.row(<PosColumn>[
      PosColumn(
        text: 'Item',
        width: 5,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: 'Qty',
        width: 2,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
      PosColumn(
        text: 'Price',
        width: 2,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
      PosColumn(
        text: 'Total',
        width: 3,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    for (final item in sale.items) {
      bytes += generator.row(<PosColumn>[
        PosColumn(
          text: _truncate(item.productName, 20),
          width: 5,
        ),
        PosColumn(
          text: '${item.quantity}',
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: _formatShort(item.unitPrice.asDouble),
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: _formatShort(item.totalAmount.asDouble),
          width: 3,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();

    bytes += generator.row(<PosColumn>[
      PosColumn(
        text: 'Subtotal',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: AppTheme.formatMoney(sale.subtotal),
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (sale.discountAmount.compareTo(Money.zero) > 0) {
      bytes += generator.row(<PosColumn>[
        PosColumn(
          text: 'Discount',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '-${AppTheme.formatMoney(sale.discountAmount)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.row(<PosColumn>[
      PosColumn(
        text: 'Tax',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: AppTheme.formatMoney(sale.taxAmount),
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.row(<PosColumn>[
      PosColumn(
        text: 'TOTAL',
        width: 8,
        styles: const PosStyles(bold: true, align: PosAlign.left),
      ),
      PosColumn(
        text: AppTheme.formatMoney(sale.totalAmount),
        width: 4,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    bytes += generator.row(<PosColumn>[
      PosColumn(
        text: 'Paid (${sale.paymentMethod})',
        width: 8,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: AppTheme.formatMoney(sale.amountPaid),
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (sale.balanceDue.compareTo(Money.zero) > 0) {
      bytes += generator.row(<PosColumn>[
        PosColumn(
          text: 'Balance Due',
          width: 8,
          styles: const PosStyles(bold: true, align: PosAlign.left),
        ),
        PosColumn(
          text: AppTheme.formatMoney(sale.balanceDue),
          width: 4,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.text(
      'Thank you for your business!',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  static String _formatShort(double value) {
    return AppTheme.formatCurrency(value).replaceAll('UGX', '').trim();
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 1)}…';
  }
}
