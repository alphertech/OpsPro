import 'package:flutter/foundation.dart';
import 'dart:io';
import 'storage_service.dart';
import 'sqlite_storage_service.dart';
import 'web_storage_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  StorageService? _storage;
  bool _initialized = false;
  String? _initError;

  Future<void> init() async {
    if (_initialized && _storage != null) return;
    try {
      if (kIsWeb) {
        _storage = WebStorageService();
      } else {
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          SqliteStorageService.initFfi();
        }
        _storage = SqliteStorageService();
      }
      await _storage!.init();
      _initialized = true;
      _initError = null;
    } catch (e) {
      _initError = e.toString();
      _initialized = false;
      _storage = null;
      rethrow;
    }
  }

  bool get isInitialized => _initialized;
  String? get initError => _initError;

  StorageService get storage {
    if (_storage == null || !_initialized) {
      throw StateError('DatabaseService is not initialized. Call init() first.');
    }
    return _storage!;
  }

  String hashPassword(String password) {
    if (_storage == null) throw StateError('DatabaseService is not initialized');
    return _storage!.hashPassword(password);
  }

  bool verifyPassword(String password, String salt, String hash) {
    if (_storage == null) throw StateError('DatabaseService is not initialized');
    return _storage!.verifyPassword(password, salt, hash);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    if (_storage == null) throw StateError('DatabaseService is not initialized');
    return await _storage!.insert(table, data).timeout(const Duration(seconds: 10));
  }

  Future<int> update(String table, Map<String, dynamic> data, {required int id}) async {
    if (_storage == null) throw StateError('DatabaseService is not initialized');
    return await _storage!.update(table, data, id: id).timeout(const Duration(seconds: 10));
  }

  Future<int> delete(String table, {required int id}) async {
    if (_storage == null) throw StateError('DatabaseService is not initialized');
    return await _storage!.delete(table, id: id).timeout(const Duration(seconds: 10));
  }

  Future<int> softDelete(String table, {required int id}) async {
    if (_storage == null) throw StateError('DatabaseService is not initialized');
    return await _storage!.softDelete(table, id: id).timeout(const Duration(seconds: 10));
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit}) async {
    if (_storage == null) throw StateError('DatabaseService is not initialized');
    return await _storage!.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit).timeout(const Duration(seconds: 10));
  }

  Future<Map<String, dynamic>?> queryOne(String table, {required int id}) async {
    if (_storage == null) throw StateError('DatabaseService is not initialized');
    return await _storage!.queryOne(table, id: id).timeout(const Duration(seconds: 10));
  }

  Future<T> transaction<T>(Future<T> Function(dynamic database) action) async {
    if (_storage == null) throw StateError('DatabaseService is not initialized');
    return await _storage!.transaction(action).timeout(const Duration(seconds: 15));
  }

  Future<void> backupDatabase(String backupPath) async {
    if (_storage == null) throw StateError('DatabaseService is not initialized');
    return await _storage!.backupDatabase(backupPath).timeout(const Duration(seconds: 30));
  }

  Future<String> getDatabasePath() async {
    if (_storage == null) throw StateError('DatabaseService is not initialized');
    return await _storage!.getDatabasePath().timeout(const Duration(seconds: 10));
  }
}
