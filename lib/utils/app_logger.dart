import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const String _logFileName = 'suubi_app_log.txt';
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;
  static const int _maxRotatedFiles = 3;
  String? _logPath;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final Directory appDataDir = await getApplicationDocumentsDirectory();
      _logPath = '${appDataDir.path}\\$_logFileName';
      _initialized = true;
    } catch (e) {
      _logPath = null;
    }
  }

  Future<void> rotateIfNeeded() async {
    if (!_initialized || _logPath == null) return;
    try {
      final file = File(_logPath!);
      if (await file.exists() && await file.length() > _maxFileSizeBytes) {
        final oldest = File('$_logPath.$_maxRotatedFiles');
        if (await oldest.exists()) await oldest.delete();
        for (int i = _maxRotatedFiles - 2; i >= 0; i--) {
          final src = i == 0 ? _logPath! : '$_logPath.$i';
          final dst = '$_logPath.${i + 1}';
          final srcFile = File(src);
          if (await srcFile.exists()) {
            await srcFile.copy(dst);
          }
        }
        await file.writeAsString('');
      }
    } catch (_) {}
  }

  Future<void> log(String message) async {
    if (!_initialized || _logPath == null) return;
    try {
      await rotateIfNeeded();
      final File file = File(_logPath!);
      final timestamp = DateTime.now().toIso8601String();
      await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append);
    } catch (e) {
      // ignore
    }
  }

  Future<void> clear() async {
    if (!_initialized || _logPath == null) return;
    try {
      final File file = File(_logPath!);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // ignore
    }
  }
}
