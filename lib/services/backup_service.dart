import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../services/database_service.dart';

class BackupService {
  static Timer? _autoBackupTimer;
  static const int _maxBackups = 7;

  static Future<String> get _backupsDirPath async {
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, 'Backups');
  }

  static Future<Directory> _getBackupsDir() async {
    final path = await _backupsDirPath;
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _generateBackupName() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'suubi_backup_$timestamp.db';
  }

  static Future<void> performBackup() async {
    final dbPath = await DatabaseService().getDatabasePath();
    final backupsDir = await _getBackupsDir();
    final backupPath = p.join(backupsDir.path, _generateBackupName());

    final source = File(dbPath);
    final size = await source.length();
    if (size > 500 * 1024 * 1024) {
      throw Exception('Database too large to backup safely');
    }

    final sink = File(backupPath).openWrite();
    await for (final chunk in source.openRead()) {
      sink.add(chunk);
    }
    await sink.close();

    final file = File(backupPath);
    final fileSize = await file.length();

    await DatabaseService().insert('backups', {
      'file_path': backupPath,
      'file_size': fileSize,
      'backup_date': DateTime.now().toIso8601String(),
      'description': 'Auto backup',
      'created_at': DateTime.now().toIso8601String(),
    });

    await _cleanOldBackups();
  }

  static Future<void> _cleanOldBackups() async {
    try {
      final backupsDir = await _getBackupsDir();
      final files = <File>[];

      await for (final entity in backupsDir.list()) {
        if (entity is File && entity.path.endsWith('.db')) {
          files.add(entity);
        }
      }

      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      for (int i = _maxBackups; i < files.length; i++) {
        try {
          await files[i].delete();
        } catch (_) {}
      }

      final records = await DatabaseService().query('backups', orderBy: 'backup_date DESC');
      for (int i = _maxBackups; i < records.length; i++) {
        try {
          final path = records[i]['file_path'] as String;
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
        try {
          final id = records[i]['id'] as int;
          await DatabaseService().delete('backups', id: id);
        } catch (_) {}
      }
    } catch (_) {}
  }

  static Future<void> startAutoBackupTimer({required int intervalHours}) async {
    await stopAutoBackup();

    _autoBackupTimer = Timer.periodic(Duration(hours: intervalHours), (_) async {
      try {
        await performBackup();
      } catch (_) {}
    });
  }

  static Future<void> startAutoBackup({required int intervalHours}) async {
    await stopAutoBackup();

    try {
      await performBackup();
    } catch (_) {}

    _autoBackupTimer = Timer.periodic(Duration(hours: intervalHours), (_) async {
      try {
        await performBackup();
      } catch (_) {}
    });
  }

  static Future<void> stopAutoBackup() async {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = null;
  }
}
