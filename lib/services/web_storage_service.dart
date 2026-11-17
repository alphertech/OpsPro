import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import '../services/crypto_service.dart';

class WebStorageService implements StorageService {
  static final WebStorageService _instance = WebStorageService._internal();
  factory WebStorageService() => _instance;
  WebStorageService._internal();

  SharedPreferences? _prefs;
  final Map<String, List<Map<String, dynamic>>> _tables = {};
  bool _initialized = false;
  final CryptoService _crypto = CryptoService();

  @override
  Future<void> init() async {
    if (_initialized) return;
    _prefs ??= await SharedPreferences.getInstance();
    await _loadData();
    _initialized = true;
  }

  Future<void> _loadData() async {
    _tables.clear();
    final keys = _prefs!.getKeys();
    for (final key in keys) {
      final value = _prefs!.getString(key);
      if (value != null && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value) as List<dynamic>;
          _tables[key] = decoded
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } catch (e) {
          _tables[key] = [];
        }
      }
    }
    if (_tables.isEmpty) {
      await _insertDefaultData();
    }
  }

  Future<void> _persist(String table) async {
    final rows = _tables[table] ?? [];
    await _prefs!.setString(table, jsonEncode(rows));
  }

  Future<void> _insertDefaultData() async {
    final questions = [
      'What is your mother\'s maiden name?',
      'What was your first pet\'s name?',
      'What is the name of your first school?',
      'What is your favorite color?',
      'What city were you born in?',
      'What is your favorite food?',
      'What is your father\'s first name?',
      'What was your childhood nickname?',
    ];
    for (final q in questions) {
      await insert('security_questions', {
        'question_text': q,
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    if ((_tables['security_config'] ?? []).isEmpty) {
      await insert('security_config', {
        'max_failed_attempts': 5,
        'lockout_duration_minutes': 15,
        'require_security_question': 1,
        'allow_pattern': 1,
        'allow_pin': 1,
        'allow_password': 1,
        'session_timeout_minutes': 15,
        'enable_f5_lock': 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  String hashPassword(String password) {
    final salt = _crypto.generateSalt();
    return _crypto.hashPassword(password, salt);
  }

  @override
  bool verifyPassword(String password, String salt, String hash) {
    if (salt.isEmpty || hash.isEmpty) return false;
    return _crypto.verifyPassword(password, salt, hash);
  }

  int _generateId(String table) {
    final rows = _tables[table] ?? [];
    if (rows.isEmpty) return 1;
    return rows.map((r) => r['id'] as int? ?? 0).reduce((a, b) => a > b ? a : b) + 1;
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final rows = _tables[table] ?? [];
    final id = _generateId(table);
    final row = Map<String, dynamic>.from(data);
    row['id'] = id;
    rows.add(row);
    _tables[table] = rows;
    await _persist(table);
    return id;
  }

  @override
  Future<int> update(String table, Map<String, dynamic> data, {required int id}) async {
    final rows = _tables[table] ?? [];
    final index = rows.indexWhere((r) => r['id'] == id);
    if (index == -1) return 0;
    final updated = Map<String, dynamic>.from(rows[index]);
    updated.addAll(data);
    updated['id'] = id;
    rows[index] = updated;
    _tables[table] = rows;
    await _persist(table);
    return 1;
  }

  @override
  Future<int> delete(String table, {required int id}) async {
    final rows = _tables[table] ?? [];
    rows.removeWhere((r) => r['id'] == id);
    _tables[table] = rows;
    await _persist(table);
    return 1;
  }

  @override
  Future<int> softDelete(String table, {required int id}) async {
    final rows = _tables[table] ?? [];
    for (final row in rows) {
      if (row['id'] == id) {
        row['is_deleted'] = 1;
        break;
      }
    }
    _tables[table] = rows;
    await _persist(table);
    return 1;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit}) async {
    var rows = List<Map<String, dynamic>>.from(_tables[table] ?? []);
    if (where != null && whereArgs != null) {
      rows = rows.where((row) {
        final regex = RegExp(r'(\w+)\s*(=|>=|<=|>|<|!=)\s*\?');
        final match = regex.firstMatch(where);
        if (match == null) return true;
        final column = match.group(1);
        final value = row[column];
        final arg = whereArgs.first;
        switch (match.group(2)) {
          case '=': return value == arg;
          case '!=': return value != arg;
          case '>': return (value as num) > (arg as num);
          case '<': return (value as num) < (arg as num);
          case '>=': return (value as num) >= (arg as num);
          case '<=': return (value as num) <= (arg as num);
          default: return true;
        }
      }).toList();
    }
    if (orderBy != null) {
      final parts = orderBy.split(' ');
      final column = parts.first;
      final desc = parts.length > 1 && parts[1].toLowerCase() == 'desc';
      rows.sort((a, b) {
        final av = a[column];
        final bv = b[column];
        if (av == null && bv == null) return 0;
        if (av == null) return desc ? 1 : -1;
        if (bv == null) return desc ? -1 : 1;
        if (av is num && bv is num) return desc ? bv.compareTo(av) : av.compareTo(bv);
        return desc ? bv.toString().compareTo(av.toString()) : av.toString().compareTo(bv.toString());
      });
    }
    if (limit != null) rows = rows.take(limit).toList();
    return rows;
  }

  @override
  Future<Map<String, dynamic>?> queryOne(String table, {required int id}) async {
    final rows = await query(table, where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(dynamic database) action) async {
    return await action(_tables);
  }

  @override
  Future<void> backupDatabase(String backupPath) async {
    // web fallback: no-op
  }

  @override
  Future<String> exportDatabaseAsSql() async {
    throw UnsupportedError('Database export is not supported on web platform.');
  }

  @override
  Future<String> getDatabasePath() async {
    return 'web_storage';
  }
}
