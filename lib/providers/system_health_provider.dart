import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class SystemHealthProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  bool _dbConnected = false;
  bool get dbConnected => _dbConnected;

  String _storageStatus = 'Unknown';
  String get storageStatus => _storageStatus;
  String _storageDetail = '';
  String get storageDetail => _storageDetail;

  String _memoryStatus = 'Unknown';
  String get memoryStatus => _memoryStatus;
  String _memoryDetail = '';
  String get memoryDetail => _memoryDetail;

  String _cpuStatus = 'Unknown';
  String get cpuStatus => _cpuStatus;
  String _cpuDetail = '';
  String get cpuDetail => _cpuDetail;

  int _dbSizeBytes = 0;
  int get dbSizeBytes => _dbSizeBytes;

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();

    await Future.wait([
      _checkDatabase(),
      _checkStorage(),
      _checkMemory(),
      _checkCpu(),
    ]);

    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> _checkDatabase() async {
    try {
      if (!_db.isInitialized) {
        _dbConnected = false;
        return;
      }
      final result = await _db.query('users', limit: 1);
      _dbConnected = result.isNotEmpty;
    } catch (e) {
      _dbConnected = false;
    }
  }

  Future<void> _checkStorage() async {
    try {
      final dbPath = await _db.getDatabasePath();
      final dbFile = File(dbPath);
      _dbSizeBytes = await dbFile.length();

      final drive = dbFile.parent.path.substring(0, 2);

      if (Platform.isWindows) {
        final result = await Process.run(
          'wmic',
          ['LogicalDisk where "DeviceID=\'$drive}\'" get FreeSpace,Size /Value'],
        );
        final output = result.stdout.toString();
        final freeMatch = _extractWmicValue(output, 'FreeSpace');
        final sizeMatch = _extractWmicValue(output, 'Size');
        if (freeMatch != null && sizeMatch != null) {
          final free = int.parse(freeMatch);
          final total = int.parse(sizeMatch);
          final used = total - free;
          final percent = total > 0 ? (used / total) * 100 : 0;
          _storageStatus = percent < 85 ? 'Available' : (percent < 95 ? 'Warning' : 'Critical');
          _storageDetail = '${_formatBytes(free)} free / ${_formatBytes(total)} total';
        }
      } else {
        _storageStatus = 'Available';
        _storageDetail = 'Checked';
      }
    } catch (e) {
      _storageStatus = 'Unknown';
      _storageDetail = '';
    }
  }

  Future<void> _checkMemory() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('wmic', [
          'OS get FreePhysicalMemory,TotalVisibleMemory /Value'
        ]);
        final output = result.stdout.toString();
        final freeMatch = _extractWmicValue(output, 'FreePhysicalMemory');
        final totalMatch = _extractWmicValue(output, 'TotalVisibleMemory');
        if (freeMatch != null && totalMatch != null) {
          final freeKb = int.parse(freeMatch);
          final totalKb = int.parse(totalMatch);
          final usedKb = totalKb - freeKb;
          final percent = totalKb > 0 ? (usedKb / totalKb) * 100 : 0;
          _memoryStatus = percent < 75 ? 'Normal' : (percent < 90 ? 'Warning' : 'Critical');
          _memoryDetail = '${_formatBytes(usedKb * 1024)} / ${_formatBytes(totalKb * 1024)}';
        }
      } else if (Platform.isLinux) {
        final meminfo = File('/proc/meminfo').readAsStringSync();
        final totalMatch = _extractProcValue(meminfo, 'MemTotal:');
        final availableMatch = _extractProcValue(meminfo, 'MemAvailable:');
        if (totalMatch != null && availableMatch != null) {
          final totalKb = int.parse(totalMatch);
          final availKb = int.parse(availableMatch);
          final usedKb = totalKb - availKb;
          final percent = totalKb > 0 ? (usedKb / totalKb) * 100 : 0;
          _memoryStatus = percent < 75 ? 'Normal' : (percent < 90 ? 'Warning' : 'Critical');
          _memoryDetail = '${_formatBytes(usedKb * 1024)} / ${_formatBytes(totalKb * 1024)}';
        }
      }
    } catch (e) {
      _memoryStatus = 'Unknown';
      _memoryDetail = '';
    }
  }

  Future<void> _checkCpu() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('wmic', [
          'CPU get LoadPercentage'
        ]);
        final output = result.stdout.toString().trim();
        final lines = output.split('\n').where((l) => l.trim().isNotEmpty).toList();
        if (lines.length > 1) {
          final loadLine = lines[1].trim();
          final load = int.tryParse(loadLine);
          if (load != null) {
            _cpuStatus = load < 75 ? 'Normal' : (load < 90 ? 'Warning' : 'Critical');
            _cpuDetail = 'CPU Load: $load%';
          }
        }
        final nameResult = await Process.run('wmic', [
          'CPU get Name'
        ]);
        final nameOutput = nameResult.stdout.toString().trim();
        final nameLines = nameOutput.split('\n').where((l) => l.trim().isNotEmpty).toList();
        if (nameLines.length > 1) {
          _cpuDetail = '${nameLines[1].trim()}\nCPU Load: ${_cpuDetail.replaceFirst('CPU Load: ', '')}';
        }
      } else {
        final result = await Process.run('sysctl', ['-n', 'hw.model']);
        _cpuDetail = result.stdout.toString().trim();
        _cpuStatus = 'Normal';
      }
    } catch (e) {
      _cpuStatus = 'Unknown';
      _cpuDetail = '';
    }
  }

  String? _extractWmicValue(String output, String key) {
    final regex = RegExp('$key\\s*=\\s*(\\d+)');
    final match = regex.firstMatch(output);
    return match?.group(1);
  }

  String? _extractProcValue(String content, String key) {
    final regex = RegExp('$key\\s+(\\d+)');
    final match = regex.firstMatch(content);
    return match?.group(1);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
