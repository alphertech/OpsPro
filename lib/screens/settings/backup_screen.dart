import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/database_service.dart';
import '../../services/backup_service.dart';
import '../../providers/app_settings_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _autoBackup = true;
  int _backupInterval = 2;
  List<Map<String, dynamic>> _backups = [];
  bool _isCreatingBackup = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    try {
      final maps = await DatabaseService().query('backups', orderBy: 'backup_date DESC');
      setState(() {
        _backups = maps.map((m) => {
          'id': m['id'],
          'path': m['file_path'],
          'name': m['file_path']?.split('\\').last ?? 'backup.db',
          'date': DateTime.parse(m['backup_date']),
          'size': m['file_size'] != null ? '${(m['file_size'] / 1024 / 1024).toStringAsFixed(1)} MB' : 'Unknown',
        }).toList();
      });
    } catch (e) {
      _backups = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Backup Management', showBackButton: true),
      drawer: const AppDrawer(currentRoute: '/settings/backup'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.backup, color: Theme.of(context).primaryColor, size: 24),
                              const SizedBox(width: 12),
                              Text('Create Backup', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Create a full backup of your database including all products, sales, customers, and settings.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  label: _isCreatingBackup ? 'Creating...' : 'Create Backup Now',
                                  icon: Icons.backup,
                                  isLoading: _isCreatingBackup,
                                  onPressed: _isCreatingBackup ? null : _createBackup,
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  isFullWidth: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomButton(
                                  label: 'Restore Backup',
                                  icon: Icons.restore,
                                  onPressed: _backups.isEmpty ? null : _restoreBackup,
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  isFullWidth: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.settings, color: Theme.of(context).primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Text('Backup Settings', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Auto-Backup'),
                      subtitle: Text('Automatically backup every $_backupInterval hours'),
                      value: _autoBackup,
                      onChanged: (value) {
                        setState(() => _autoBackup = value);
                        final settings = Provider.of<AppSettingsProvider>(context, listen: false);
                        settings.updateBackupSettings(autoBackup: value);
                        if (value) {
                          BackupService.startAutoBackup(intervalHours: _backupInterval);
                        } else {
                          BackupService.stopAutoBackup();
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_autoBackup) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Backup Interval: ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: DropdownButton<int>(
                              value: _backupInterval,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('Every Hour')),
                                DropdownMenuItem(value: 2, child: Text('Every 2 Hours')),
                                DropdownMenuItem(value: 6, child: Text('Every 6 Hours')),
                                DropdownMenuItem(value: 12, child: Text('Every 12 Hours')),
                                DropdownMenuItem(value: 24, child: Text('Every 24 Hours')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _backupInterval = value);
                                  final settings = Provider.of<AppSettingsProvider>(context, listen: false);
                                  settings.updateBackupSettings(backupIntervalHours: value);
                                  if (_autoBackup) {
                                    BackupService.startAutoBackup(intervalHours: value);
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Backup Location'),
                      subtitle: const Text('Documents/Plexus/Backups'),
                      trailing: const Icon(CupertinoIcons.folder_open),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Backup location: Documents/Plexus/Backups')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: Theme.of(context).primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Text('Available Backups', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_backups.isEmpty)
                      const Text('No backups yet. Create your first backup above.', style: TextStyle(color: Colors.grey))
                    else
                      ..._backups.map(
                        (backup) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.insert_drive_file, color: Colors.grey[600], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      backup['name'],
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${DateFormat('dd MMM yyyy HH:mm').format(backup['date'])} - ${backup['size']}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.restore, size: 18, color: Colors.blue),
                                    tooltip: 'Restore',
                                    onPressed: () => _restoreBackup(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    tooltip: 'Delete',
                                    onPressed: () async {
                                      final backupId = backup['id'] as int?;
                                      if (backupId == null) return;
                                      final messenger = ScaffoldMessenger.of(context);
                                      final confirmed = await PasswordConfirmationDialog.show(context);
                                      if (!confirmed || !mounted) return;

                                      await DatabaseService().delete('backups', id: backupId);
                                      _loadBackups();
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          const SnackBar(content: Text('Backup deleted'), backgroundColor: Colors.green),
                                        );
                                      }
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    final confirmed = await PasswordConfirmationDialog.show(context);
    if (!confirmed || !mounted) return;

    setState(() => _isCreatingBackup = true);
    try {
      await BackupService.performBackup();
      await _loadBackups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _restoreBackup() async {
    if (_backups.isEmpty) return;

    final selectedBackup = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Backup to Restore'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _backups.map((backup) {
                return ListTile(
                  title: Text(backup['name'] ?? 'backup.db'),
                  subtitle: Text('${backup['date']} - ${backup['size']}'),
                  onTap: () => Navigator.pop(context, backup),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ],
        );
      },
    );

    if (selectedBackup == null || !mounted) return;

    final backupPath = selectedBackup['path'] as String?;
    if (backupPath == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text('This will replace your current data with the selected backup. The app will restart. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final passwordConfirmed = await PasswordConfirmationDialog.show(context);
    if (!passwordConfirmed || !mounted) return;

    setState(() => _isCreatingBackup = true);
    try {
      final dbPath = await DatabaseService().getDatabasePath();
      final sourceFile = File(backupPath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(dbPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored. Please restart the app.'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup file not found.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingBackup = false);
    }
  }
}
