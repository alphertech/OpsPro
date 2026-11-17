import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class AppStartupService {
  static final AppStartupService _instance = AppStartupService._internal();
  factory AppStartupService() => _instance;
  AppStartupService._internal();

  static const String _keyInstalled = 'app_installed';
  static const String _keyAccountCreated = 'account_created';
  static const String _keyLoggedIn = 'user_logged_in';
  static const String _keyUserId = 'user_id';

  SharedPreferences? _prefs;

  Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isInstalled {
    if (_prefs == null) return false;
    return _prefs!.getBool(_keyInstalled) ?? false;
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setInstalled(bool value) async {
    await _ensurePrefs();
    await _prefs!.setBool(_keyInstalled, value);
  }

  bool get isAccountCreated {
    if (_prefs == null) return false;
    return _prefs!.getBool(_keyAccountCreated) ?? false;
  }

  Future<void> setAccountCreated(bool value) async {
    await _ensurePrefs();
    await _prefs!.setBool(_keyAccountCreated, value);
  }

  bool get isLoggedIn {
    if (_prefs == null) return false;
    return _prefs!.getBool(_keyLoggedIn) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    await _ensurePrefs();
    await _prefs!.setBool(_keyLoggedIn, value);
  }

  int? get userId {
    if (_prefs == null) return null;
    return _prefs!.getInt(_keyUserId);
  }

  Future<void> setUserId(int? value) async {
    await _ensurePrefs();
    if (value == null) {
      await _prefs!.remove(_keyUserId);
    } else {
      await _prefs!.setInt(_keyUserId, value);
    }
  }

  Future<void> logout() async {
    await setLoggedIn(false);
    await setUserId(null);
  }

  Future<bool> hasActiveSession() async {
    if (!isLoggedIn) return false;
    final userId = this.userId;
    if (userId == null) return false;

    try {
      final db = DatabaseService();
      final users = await db.query(
        'users',
        where: 'id = ? AND is_active = ? AND setup_completed = ?',
        whereArgs: [userId, 1, 1],
        limit: 1,
      );
      return users.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, bool>> getStartupState() async {
    if (_prefs == null) {
      await init();
    }

    final hasSession = await hasActiveSession();

    return {
      'installed': isInstalled,
      'accountCreated': isAccountCreated,
      'isLoggedIn': hasSession,
    };
  }

  Future<void> markInstalled() async {
    await setInstalled(true);
  }

  Future<void> markAccountCreated(int userId) async {
    await setAccountCreated(true);
    await setUserId(userId);
    await setLoggedIn(true);
  }

  Future<void> markLogin(int userId) async {
    await setLoggedIn(true);
    await setUserId(userId);
  }

  Future<void> reset() async {
    if (_prefs == null) return;
    await _prefs!.clear();
  }
}
