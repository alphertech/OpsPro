import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/crypto_service.dart';
import 'security_provider.dart';
import '../services/app_startup_service.dart';

class AuthProvider extends ChangeNotifier {
  final CryptoService _crypto = CryptoService();
  final AppStartupService _startup = AppStartupService();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isSessionLocked = false;
  String? _errorMessage;

  AuthProvider() {
    _syncFromSecurity();
  }

  void _syncFromSecurity() {
    final security = SecurityProvider();
    _currentUser = security.currentUser;
    _isAuthenticated = security.isAuthenticated;
    _isSessionLocked = security.isSessionLocked;
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isSessionLocked => _isSessionLocked;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String username, String password) async {
    _errorMessage = null;
    final security = SecurityProvider();
    final success = await security.loginWithUsername(username, password);
    if (success) {
      _syncFromSecurity();
      final userId = security.currentUser?.id;
      if (userId != null) {
        await _startup.markLogin(userId);
      }
    } else {
      _errorMessage = security.errorMessage;
    }
    notifyListeners();
    return success;
  }

  Future<bool> unlockSession(String pin) async {
    _errorMessage = null;
    final security = SecurityProvider();
    final success = await security.authenticateWithPin(pin);
    if (success) {
      _syncFromSecurity();
      final userId = security.currentUser?.id;
      if (userId != null) {
        await _startup.markLogin(userId);
      }
    } else {
      _errorMessage = security.errorMessage;
    }
    notifyListeners();
    return success;
  }

  void lockSession() {
    _isSessionLocked = true;
    SecurityProvider().lockSession();
    notifyListeners();
  }

  Future<void> logout() async {
    await SecurityProvider().logout();
    await _startup.logout();
    _currentUser = null;
    _isAuthenticated = false;
    _isSessionLocked = false;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    switch (_currentUser!.role) {
      case 'Admin':
        return true;
      case 'Manager':
        return permission != 'payroll_view' && permission != 'system_settings';
      case 'Cashier':
        return permission == 'pos_access' || permission == 'sales_view';
      default:
        return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final security = SecurityProvider();
    final success = await security.resetPassword(oldPassword, newPassword);
    if (success) {
      _syncFromSecurity();
    }
    return success;
  }

  Future<List<User>> getUsers() async {
    return await SecurityProvider().getUsers();
  }

  Future<bool> createUser(User user) async {
    return await SecurityProvider().createUser(user);
  }

  Future<bool> updateUser(User user) async {
    return await SecurityProvider().updateUser(user);
  }

  Future<bool> deleteUser(int userId) async {
    return await SecurityProvider().deleteUser(userId);
  }

  String hashPassword(String password) {
    return _crypto.hashPassword(password, _crypto.generateSalt());
  }

  Future<bool> resetUserPassword(int userId, String newPassword) async {
    return await SecurityProvider().resetUserPassword(userId, newPassword);
  }
}
