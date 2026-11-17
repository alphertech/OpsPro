import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const String _defaultCurrencySymbol = 'UGX';
  static const String _defaultCurrencyPosition = 'Left';
  static const int _defaultDecimalPlaces = 0;
  static const String _defaultDateFormat = 'dd/MM/yyyy';
  static const String _defaultInvoicePrefix = 'INV-';
  static const int _defaultNextInvoiceNumber = 1001;
  static const double _defaultTaxRate = 0.0;

  final DatabaseService _db = DatabaseService();

  String _currencySymbol = _defaultCurrencySymbol;
  String _currencyPosition = _defaultCurrencyPosition;
  int _decimalPlaces = _defaultDecimalPlaces;
  String _dateFormat = _defaultDateFormat;
  String _invoicePrefix = _defaultInvoicePrefix;
  int _nextInvoiceNumber = _defaultNextInvoiceNumber;
  double _defaultTaxRateValue = _defaultTaxRate;
  bool _taxInclusive = false;
  bool _allowNegativeStock = false;
  bool _requireCustomer = false;
  bool _enableF5Lock = true;
  bool _autoBackup = true;
  int _backupIntervalHours = 2;
  bool _isLoading = false;
  String? _errorMessage;

  String get currencySymbol => _currencySymbol;
  String get currencyPosition => _currencyPosition;
  int get decimalPlaces => _decimalPlaces;
  String get dateFormat => _dateFormat;
  String get invoicePrefix => _invoicePrefix;
  int get nextInvoiceNumber => _nextInvoiceNumber;
  double get defaultTaxRate => _defaultTaxRateValue;
  bool get taxInclusive => _taxInclusive;
  bool get allowNegativeStock => _allowNegativeStock;
  bool get requireCustomer => _requireCustomer;
  bool get enableF5Lock => _enableF5Lock;
  bool get autoBackup => _autoBackup;
  int get backupIntervalHours => _backupIntervalHours;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final maps = await Future.microtask(() async {
        return await _db.query('security_config', limit: 1);
      });
      if (maps.isNotEmpty) {
        final config = maps.first;
        _enableF5Lock = (config['enable_f5_lock'] as int? ?? 1) == 1;
      }

      final prefs = await _loadPreferences();
      _currencySymbol = prefs['currencySymbol'] ?? _currencySymbol;
      _currencyPosition = prefs['currencyPosition'] ?? _currencyPosition;
      _decimalPlaces = prefs['decimalPlaces'] ?? _decimalPlaces;
      _dateFormat = prefs['dateFormat'] ?? _dateFormat;
      _invoicePrefix = prefs['invoicePrefix'] ?? _invoicePrefix;
      _nextInvoiceNumber = prefs['nextInvoiceNumber'] ?? _nextInvoiceNumber;
      _defaultTaxRateValue = prefs['defaultTaxRate'] ?? _defaultTaxRateValue;
      _taxInclusive = prefs['taxInclusive'] ?? _taxInclusive;
      _allowNegativeStock = prefs['allowNegativeStock'] ?? _allowNegativeStock;
      _requireCustomer = prefs['requireCustomer'] ?? _requireCustomer;
    } catch (e) {
      _errorMessage = 'Failed to load settings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _loadPreferences() async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('app_preferences', limit: 1);
      });
      if (maps.isNotEmpty) {
        return Map<String, dynamic>.from(maps.first);
      }
    } catch (e) {
      // table may not exist yet
    }
    return {};
  }

  Future<void> _savePreferences(Map<String, dynamic> prefs) async {
    try {
      await _db.insert('app_preferences', prefs);
    } catch (e) {
      try {
        await _db.update('app_preferences', prefs, id: 1);
      } catch (e) {
        // ignore
      }
    }
  }

  Future<void> updateCurrencySettings({
    String? currencySymbol,
    String? currencyPosition,
    int? decimalPlaces,
  }) async {
    if (currencySymbol != null) _currencySymbol = currencySymbol;
    if (currencyPosition != null) _currencyPosition = currencyPosition;
    if (decimalPlaces != null) _decimalPlaces = decimalPlaces;
    notifyListeners();
    await _savePreferences({
      'currencySymbol': _currencySymbol,
      'currencyPosition': _currencyPosition,
      'decimalPlaces': _decimalPlaces,
    });
  }

  Future<void> updateDateFormat(String format) async {
    _dateFormat = format;
    notifyListeners();
    await _savePreferences({'dateFormat': _dateFormat});
  }

  Future<void> updateInvoiceSettings({
    String? invoicePrefix,
    int? nextInvoiceNumber,
  }) async {
    if (invoicePrefix != null) _invoicePrefix = invoicePrefix;
    if (nextInvoiceNumber != null) _nextInvoiceNumber = nextInvoiceNumber;
    notifyListeners();
    await _savePreferences({
      'invoicePrefix': _invoicePrefix,
      'nextInvoiceNumber': _nextInvoiceNumber,
    });
  }

  Future<void> updateTaxSettings({
    double? defaultTaxRate,
    bool? taxInclusive,
  }) async {
    if (defaultTaxRate != null) _defaultTaxRateValue = defaultTaxRate;
    if (taxInclusive != null) _taxInclusive = taxInclusive;
    notifyListeners();
    await _savePreferences({
      'defaultTaxRate': _defaultTaxRateValue,
      'taxInclusive': _taxInclusive,
    });
  }

  Future<void> updateOperationalSettings({
    bool? allowNegativeStock,
    bool? requireCustomer,
    bool? enableF5Lock,
  }) async {
    if (allowNegativeStock != null) _allowNegativeStock = allowNegativeStock;
    if (requireCustomer != null) _requireCustomer = requireCustomer;
    if (enableF5Lock != null) _enableF5Lock = enableF5Lock;
    notifyListeners();
    await _savePreferences({
      'allowNegativeStock': _allowNegativeStock,
      'requireCustomer': _requireCustomer,
      'enableF5Lock': _enableF5Lock,
    });
  }

  Future<void> updateBackupSettings({
    bool? autoBackup,
    int? backupIntervalHours,
  }) async {
    if (autoBackup != null) _autoBackup = autoBackup;
    if (backupIntervalHours != null) _backupIntervalHours = backupIntervalHours;
    notifyListeners();
    await _savePreferences({
      'autoBackup': _autoBackup,
      'backupIntervalHours': _backupIntervalHours,
    });
  }

}
