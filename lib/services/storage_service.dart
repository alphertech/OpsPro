abstract class StorageService {
  Future<void> init();
  Future<int> insert(String table, Map<String, dynamic> data);
  Future<int> update(String table, Map<String, dynamic> data, {required int id});
  Future<int> delete(String table, {required int id});
  Future<int> softDelete(String table, {required int id});
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit});
  Future<Map<String, dynamic>?> queryOne(String table, {required int id});
  Future<T> transaction<T>(Future<T> Function(dynamic database) action);
  Future<void> backupDatabase(String backupPath);
  Future<String> getDatabasePath();
  Future<String> exportDatabaseAsSql();
  String hashPassword(String password);
  bool verifyPassword(String password, String salt, String hash);
}
