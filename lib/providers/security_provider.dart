import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/security.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/crypto_service.dart';
import '../services/app_startup_service.dart';

class SecurityProvider extends ChangeNotifier {
  static final SecurityProvider _instance = SecurityProvider._internal();
  factory SecurityProvider() => _instance;
  SecurityProvider._internal();

  final DatabaseService _db = DatabaseService();
  final CryptoService _crypto = CryptoService();
  final AppStartupService _startup = AppStartupService();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isSessionLocked = false;
  bool _isSetupComplete = false;
  bool _isFirstRun = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  DateTime? _lastActivity;
  Timer? _sessionTimer;

  DateTime? _lastPasswordConfirmation;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isSessionLocked => _isSessionLocked;
  bool get isSetupComplete => _isSetupComplete;
  bool get isFirstRun => _isFirstRun;
  String? get errorMessage => _errorMessage;
  int get failedAttempts => _failedAttempts;
  bool get isLockedOut => _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  bool get isPasswordConfirmationRequired {
    if (_lastPasswordConfirmation == null) return true;
    final elapsed = DateTime.now().difference(_lastPasswordConfirmation!).inSeconds;
    return elapsed > 120;
  }

  void markPasswordConfirmed() {
    _lastPasswordConfirmation = DateTime.now();
  }
  String? get lockType => _currentUser?.lockType;
  bool get isReady => _initCompleter != null && _initCompleter!.isCompleted;

  SecuritySettings settings = const SecuritySettings();
  Completer<void>? _initCompleter;

  Future<void> init() async {
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    try {
      await _startup.init();
      // Run database operations on background task to avoid blocking UI
      await Future.microtask(() async {
        await _loadSecurityConfig();
        await _checkSetupStatus();
        await _restoreSession();
      });
      _startSessionTimer();
      notifyListeners();
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.complete();
      }
    } catch (e) {
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.completeError(e);
      }
      rethrow;
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_isAuthenticated && !_isSessionLocked) {
        checkSessionTimeout();
      }
    });
  }

  Future<void> _restoreSession() async {
    try {
      final hasSession = await _startup.hasActiveSession();
      if (!hasSession) return;

      final userId = _startup.userId;
      if (userId == null) return;

      final users = await _db.query(
        'users',
        where: 'id = ? AND is_active = ?',
        whereArgs: [userId, 1],
        limit: 1,
      );

      if (users.isEmpty) {
        await _startup.logout();
        return;
      }

      final user = User.fromMap(users.first);
      _currentUser = user;
      _failedAttempts = user.failedAttempts;
      _lockedUntil = user.lockedUntil;

      if (user.lockoutLevel >= 3 ||
          (user.lockedUntil != null &&
              DateTime.now().isBefore(user.lockedUntil!))) {
        // Account is disabled or temporarily locked: do not auto-restore
        // the session (mirrors the lockout enforcement in loginWithUsername).
        await _startup.logout();
        _currentUser = null;
        notifyListeners();
        return;
      }

      _isAuthenticated = true;
      _isSessionLocked = false;
      _lastActivity = DateTime.now();
      notifyListeners();
    } catch (e) {
      await _startup.logout();
    }
  }

  void updateActivity() {
    if (_isAuthenticated && !_isSessionLocked) {
      _lastActivity = DateTime.now();
    }
  }

  bool checkSessionTimeout() {
    if (_isAuthenticated && !_isSessionLocked && _lastActivity != null) {
      final elapsed = DateTime.now().difference(_lastActivity!).inMinutes;
      final timeoutMinutes = settings.sessionTimeoutMinutes;
      if (elapsed >= timeoutMinutes) {
        lockSession();
        return true;
      }
      if (elapsed >= timeoutMinutes - 2 && elapsed < timeoutMinutes) {
        _notifySessionWarning();
      }
    }
    return false;
  }

  void _notifySessionWarning() {
    if (_sessionWarningCallback != null) {
      _sessionWarningCallback!();
    }
  }

  VoidCallback? _sessionWarningCallback;

  void setSessionWarningCallback(VoidCallback? callback) {
    _sessionWarningCallback = callback;
  }

  Future<void> _loadSecurityConfig() async {
    try {
      final maps = await _db.query('security_config', limit: 1);
      if (maps.isNotEmpty) {
        final config = SecurityConfig.fromMap(maps.first);
        settings = config.toSettings();
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load security config: $e';
      notifyListeners();
    }
  }

  Future<bool> saveSecurityConfig(SecuritySettings newSettings) async {
    try {
      final maps = await _db.query('security_config', limit: 1);
      final now = DateTime.now().toIso8601String();
      if (maps.isNotEmpty) {
        await _db.update('security_config', {
          'max_failed_attempts': newSettings.maxFailedAttempts,
          'lockout_duration_minutes': newSettings.lockoutDurationMinutes,
          'require_security_question': newSettings.requireSecurityQuestion ? 1 : 0,
          'allow_pattern': newSettings.allowPattern ? 1 : 0,
          'allow_pin': newSettings.allowPin ? 1 : 0,
          'allow_password': newSettings.allowPassword ? 1 : 0,
          'session_timeout_minutes': newSettings.sessionTimeoutMinutes,
          'enable_f5_lock': newSettings.enableF5Lock ? 1 : 0,
          'updated_at': now,
        }, id: maps.first['id']);
      } else {
        await _db.insert('security_config', {
          'max_failed_attempts': newSettings.maxFailedAttempts,
          'lockout_duration_minutes': newSettings.lockoutDurationMinutes,
          'require_security_question': newSettings.requireSecurityQuestion ? 1 : 0,
          'allow_pattern': newSettings.allowPattern ? 1 : 0,
          'allow_pin': newSettings.allowPin ? 1 : 0,
          'allow_password': newSettings.allowPassword ? 1 : 0,
          'session_timeout_minutes': newSettings.sessionTimeoutMinutes,
          'enable_f5_lock': newSettings.enableF5Lock ? 1 : 0,
          'updated_at': now,
        });
      }
      settings = newSettings;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save security config: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _checkSetupStatus() async {
    try {
      final users = await _db.query('users', where: 'is_active = ?', whereArgs: [1]);
      _isFirstRun = users.isEmpty;
      _isSetupComplete = users.any((u) => (u['setup_completed'] as int? ?? 0) == 1);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to check setup status: $e';
      notifyListeners();
    }
  }

  Future<bool> loginWithUsername(String username, String password) async {
    try {
      final maps = await _db.query('users', where: 'username = ? AND is_active = ?', whereArgs: [username, 1]);
      if (maps.isEmpty) {
        _errorMessage = 'Invalid username or password.';
        notifyListeners();
        return false;
      }

      final user = User.fromMap(maps.first);
      _currentUser = user;

      if (user.lockoutLevel >= 3) {
        _errorMessage = 'System disabled. Consult System Admin for help. System inactive now.';
        notifyListeners();
        return false;
      }

      if (user.lockedUntil != null && DateTime.now().isBefore(user.lockedUntil!)) {
        _lockedUntil = user.lockedUntil;
        _failedAttempts = user.failedAttempts;
        _errorMessage = 'Account locked. Try again in ${_getRemainingLockoutMinutes()} minutes.';
        notifyListeners();
        return false;
      }

      final salt = user.passwordSalt;
      bool isValid = false;
      if (salt != null && salt.isNotEmpty) {
        isValid = _crypto.verifyPassword(password, salt, user.passwordHash);
      } else {
        isValid = _legacyHash(password) == user.passwordHash;
      }

      if (isValid) {
        if ((user.passwordSalt ?? '').isEmpty) {
          await _upgradePasswordHash(password);
        }
        await _resetFailedAttempts(user.id!);
        _onLoginSuccess();
        return true;
      } else {
        _failedAttempts = user.failedAttempts + 1;
        _lastActivity = DateTime.now();
        _logSecurityEvent('login_failed', 'Failed attempt $_failedAttempts for user $username');

        if (user.lockoutLevel == 0 && _failedAttempts >= settings.maxFailedAttempts) {
          _lockedUntil = DateTime.now().add(Duration(minutes: settings.lockoutDurationMinutes));
          _errorMessage = 'Password limit exceeded. System deactivated for ${settings.lockoutDurationMinutes} minutes.';
          _logSecurityEvent('account_locked', 'Account locked for ${settings.lockoutDurationMinutes} minutes');
          await _persistLockout(settings.lockoutDurationMinutes, 1);
        } else if (user.lockoutLevel == 1 && _failedAttempts >= 3) {
          _lockedUntil = DateTime.now().add(const Duration(hours: 3));
          _errorMessage = 'Password limit exceeded again. System deactivated for 3 hours.';
          _logSecurityEvent('account_locked', 'Account locked for 3 hours');
          await _persistLockout(3, 2);
        } else if (user.lockoutLevel == 2 && _failedAttempts >= 2) {
          _lockedUntil = DateTime.now().add(const Duration(days: 365));
          _errorMessage = 'System disabled. Consult System Admin for help. System inactive now.';
          _logSecurityEvent('account_locked', 'Account permanently locked');
          await _persistLockout(999, 3);
        } else {
          _errorMessage = 'Wrong password. Re-enter again.';
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _verifyPassword(String password) async {
    if (_currentUser == null) return false;

    final salt = _currentUser!.passwordSalt;
    if (salt != null && salt.isNotEmpty) {
      return _crypto.verifyPassword(password, salt, _currentUser!.passwordHash);
    }

    return _verifyLegacyPassword(password);
  }

  bool _verifyLegacyPassword(String password) {
    final legacyHash = _legacyHash(password);
    return legacyHash == _currentUser!.passwordHash;
  }

  Future<void> _upgradePasswordHash(String password) async {
    if (_currentUser == null) return;
    final salt = _crypto.generateSalt();
    final newHash = _crypto.hashPassword(password, salt);
    await _db.update('users', {
      'password_hash': newHash,
      'password_salt': salt,
      'updated_at': DateTime.now().toIso8601String(),
    }, id: _currentUser!.id!);
    _currentUser = _currentUser!.copyWith(passwordHash: newHash, passwordSalt: salt);
  }

  Future<bool> authenticateWithPassword(String password) async {
    if (_currentUser == null) {
      _errorMessage = 'No user account found. Please complete security setup.';
      notifyListeners();
      return false;
    }

    if (_currentUser!.lockoutLevel >= 3) {
      _errorMessage = 'System disabled. Consult System Admin for help. System inactive now.';
      notifyListeners();
      return false;
    }

    if (isLockedOut) {
      _errorMessage = 'Account locked. Try again in ${_getRemainingLockoutMinutes()} minutes.';
      notifyListeners();
      return false;
    }

    final isValid = await _verifyPassword(password);

    if (isValid) {
      if ((_currentUser!.passwordSalt ?? '').isEmpty) {
        await _upgradePasswordHash(password);
      }
      _onLoginSuccess();
      return true;
    } else {
      await _onLoginFailure();
      return false;
    }
  }

  Future<bool> authenticateWithPin(String pin) async {
    if (_currentUser == null) {
      _errorMessage = 'No user account found. Please complete security setup.';
      notifyListeners();
      return false;
    }

    if (_currentUser!.lockoutLevel >= 3) {
      _errorMessage = 'System disabled. Consult System Admin for help. System inactive now.';
      notifyListeners();
      return false;
    }

    if (isLockedOut) {
      _errorMessage = 'Account locked. Try again in ${_getRemainingLockoutMinutes()} minutes.';
      notifyListeners();
      return false;
    }

    final salt = _currentUser!.pinSalt;
    if (salt != null && salt.isNotEmpty && _currentUser!.pinHash != null) {
      final isValid = _crypto.verifyPin(pin, salt, _currentUser!.pinHash!);
      if (isValid) {
        _onLoginSuccess();
        return true;
      }
    } else if (_currentUser!.pin != null && _currentUser!.pin!.isNotEmpty) {
      final isValid = _legacyHash(pin) == _currentUser!.pin;
      if (isValid) {
        await _upgradePinHash(pin);
        _onLoginSuccess();
        return true;
      }
    }

    await _onLoginFailure();
    return false;
  }

  Future<bool> authenticateWithPattern(String pattern) async {
    if (_currentUser == null) {
      _errorMessage = 'No user account found. Please complete security setup.';
      notifyListeners();
      return false;
    }

    if (_currentUser!.lockoutLevel >= 3) {
      _errorMessage = 'System disabled. Consult System Admin for help. System inactive now.';
      notifyListeners();
      return false;
    }

    if (isLockedOut) {
      _errorMessage = 'Account locked. Try again in ${_getRemainingLockoutMinutes()} minutes.';
      notifyListeners();
      return false;
    }

    final salt = _currentUser!.patternSalt;
    if (salt != null && salt.isNotEmpty && _currentUser!.patternHash != null) {
      final isValid = _crypto.verifyPattern(pattern, salt, _currentUser!.patternHash!);
      if (isValid) {
        _onLoginSuccess();
        return true;
      }
    } else {
      final legacyHash = _hashPattern(pattern);
      if (_currentUser!.patternHash == legacyHash) {
        await _upgradePatternHash(pattern);
        _onLoginSuccess();
        return true;
      }
    }

    await _onLoginFailure();
    return false;
  }

  void _onLoginSuccess() {
    _failedAttempts = 0;
    _lockedUntil = null;
    _isAuthenticated = true;
    _isSessionLocked = false;
    _errorMessage = null;
    _lastActivity = DateTime.now();
    _updateLastLogin();
    _logSecurityEvent('login_success', 'User logged in successfully');
    _startSessionTimer();
    if (_currentUser != null) {
      _startup.markLogin(_currentUser!.id!);
    }
    notifyListeners();
  }

  Future<void> _updateLastLogin() async {
    if (_currentUser == null) return;
    try {
      final now = DateTime.now().toIso8601String();
      await _db.update('users', {
        'last_login': now,
        'updated_at': now,
      }, id: _currentUser!.id!);
      _currentUser = _currentUser!.copyWith(lastLogin: DateTime.now());
    } catch (e) {
      // silent fail
    }
  }

  Future<void> _onLoginFailure() async {
    _failedAttempts++;
    _lastActivity = DateTime.now();
    _logSecurityEvent('login_failed', 'Failed attempt $_failedAttempts');

    final lockoutLevel = _currentUser?.lockoutLevel ?? 0;

    if (lockoutLevel == 0 && _failedAttempts >= settings.maxFailedAttempts) {
      _lockedUntil = DateTime.now().add(Duration(minutes: settings.lockoutDurationMinutes));
      _errorMessage = 'Password limit exceeded. System deactivated for ${settings.lockoutDurationMinutes} minutes.';
      _logSecurityEvent('account_locked', 'Account locked for ${settings.lockoutDurationMinutes} minutes');
      await _persistLockout(settings.lockoutDurationMinutes, 1);
    } else if (lockoutLevel == 1 && _failedAttempts >= 3) {
      _lockedUntil = DateTime.now().add(const Duration(hours: 3));
      _errorMessage = 'Password limit exceeded again. System deactivated for 3 hours.';
      _logSecurityEvent('account_locked', 'Account locked for 3 hours');
      await _persistLockout(3, 2);
    } else if (lockoutLevel == 2 && _failedAttempts >= 2) {
      _lockedUntil = DateTime.now().add(const Duration(days: 365));
      _errorMessage = 'System disabled. Consult System Admin for help. System inactive now.';
      _logSecurityEvent('account_locked', 'Account permanently locked');
      await _persistLockout(999, 3);
    } else if (lockoutLevel >= 3) {
      _errorMessage = 'System disabled. Consult System Admin for help. System inactive now.';
    } else {
      _errorMessage = 'Wrong password. Re-enter again.';
    }
    notifyListeners();
  }

  Future<void> _persistLockout(int minutes, int level) async {
    if (_currentUser == null) return;
    try {
      final lockedUntil = DateTime.now().add(Duration(minutes: minutes));
      await _db.update('users', {
        'failed_attempts': _failedAttempts,
        'locked_until': lockedUntil.toIso8601String(),
        'lockout_level': level,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: _currentUser!.id!);
      _currentUser = _currentUser!.copyWith(
        failedAttempts: _failedAttempts,
        lockedUntil: lockedUntil,
        lockoutLevel: level,
      );
    } catch (e) {
      _errorMessage = 'Failed to persist lockout: $e';
      notifyListeners();
    }
  }

  Future<void> _resetFailedAttempts(int userId) async {
    _failedAttempts = 0;
    _lockedUntil = null;
    try {
      await _db.update('users', {
        'failed_attempts': 0,
        'locked_until': null,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: userId);
    } catch (e) {
      _errorMessage = 'Failed to reset attempts: $e';
      notifyListeners();
    }
  }

  Future<bool> unlockAccount(String securityAnswer) async {
    if (_currentUser == null) return false;

    final salt = _currentUser!.securityAnswerSalt;
    if (salt != null && salt.isNotEmpty && _currentUser!.securityAnswerHash != null) {
      if (_crypto.verifyAnswer(securityAnswer, salt, _currentUser!.securityAnswerHash!)) {
        _failedAttempts = 0;
        _lockedUntil = null;
        _errorMessage = null;
        _logSecurityEvent('account_unlocked', 'Account unlocked via security question');
        notifyListeners();
        return true;
      }
    } else if (_currentUser!.securityAnswerHash != null) {
      final legacyHash = _hashAnswer(securityAnswer);
      if (_currentUser!.securityAnswerHash == legacyHash) {
        await _upgradeSecurityAnswerHash(securityAnswer);
        _failedAttempts = 0;
        _lockedUntil = null;
        _errorMessage = null;
        _logSecurityEvent('account_unlocked', 'Account unlocked via security question');
        notifyListeners();
        return true;
      }
    }

    _logSecurityEvent('unlock_failed', 'Failed unlock attempt via security question');
    return false;
  }

  Future<bool> resetPassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) return false;

      final currentHash = _currentUser!.passwordHash;
      final currentSalt = _currentUser!.passwordSalt;
      bool valid = false;
      if (currentSalt != null && currentSalt.isNotEmpty) {
        valid = _crypto.verifyPassword(oldPassword, currentSalt, currentHash);
      } else {
        valid = _legacyHash(oldPassword) == currentHash;
      }

    if (!valid) {
      _errorMessage = 'Current password is incorrect.';
      return false;
    }

    if (newPassword.length < 4) {
      _errorMessage = 'New password must be at least 4 characters.';
      return false;
    }

    try {
      final salt = _crypto.generateSalt();
      final newHash = _crypto.hashPassword(newPassword, salt);
      await _db.update('users', {
        'password_hash': newHash,
        'password_salt': salt,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: _currentUser!.id!);

      _currentUser = _currentUser!.copyWith(passwordHash: newHash, passwordSalt: salt);
      _logSecurityEvent('password_changed', 'Password was changed successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update password: $e';
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    if (_currentUser == null) return false;

    if (newPassword.length < 4) {
      _errorMessage = 'New password must be at least 4 characters.';
      return false;
    }

    try {
      final salt = _crypto.generateSalt();
      final newHash = _crypto.hashPassword(newPassword, salt);
      await _db.update('users', {
        'password_hash': newHash,
        'password_salt': salt,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: _currentUser!.id!);

      _currentUser = _currentUser!.copyWith(passwordHash: newHash, passwordSalt: salt);
      _logSecurityEvent('password_changed', 'Password was changed successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update password: $e';
      return false;
    }
  }

  Future<bool> resetPasswordWithPin(String pin, String newPassword) async {
    if (_currentUser == null) return false;

      final pinSalt = _currentUser!.pinSalt;
      bool pinValid = false;
      if (pinSalt != null && pinSalt.isNotEmpty && _currentUser!.pinHash != null) {
        pinValid = _crypto.verifyPin(pin, pinSalt, _currentUser!.pinHash!);
      } else if (_currentUser!.pin != null) {
        pinValid = _legacyHash(pin) == _currentUser!.pin;
      }

    if (!pinValid) {
      _errorMessage = 'Invalid PIN.';
      return false;
    }

    if (newPassword.length < 4) {
      _errorMessage = 'New password must be at least 4 characters.';
      return false;
    }

    try {
      final salt = _crypto.generateSalt();
      final newHash = _crypto.hashPassword(newPassword, salt);
      await _db.update('users', {
        'password_hash': newHash,
        'password_salt': salt,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: _currentUser!.id!);

      _currentUser = _currentUser!.copyWith(passwordHash: newHash, passwordSalt: salt);
      _logSecurityEvent('password_reset', 'Password was reset using PIN');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reset password: $e';
      return false;
    }
  }

  /// Returns the security-question challenge for a given username so the
  /// login screen can offer password recovery without an active session.
  /// Returns `null` if no matching active account exists. Otherwise a map
  /// with `found`/`hasQuestion`/`question`/`questionId`.
  Future<Map<String, dynamic>?> getPasswordResetChallenge(String username) async {
    try {
      final maps = await _db.query(
        'users',
        where: 'username = ? AND is_active = ?',
        whereArgs: [username, 1],
        limit: 1,
      );
      if (maps.isEmpty) return null;

      final user = User.fromMap(maps.first);
      if (user.securityQuestionId == null) {
        return <String, dynamic>{'found': true, 'hasQuestion': false};
      }

      final questions = await getSecurityQuestions();
      final question = questions.firstWhere(
        (q) => q.id == user.securityQuestionId,
        orElse: () => SecurityQuestion(
          id: user.securityQuestionId!,
          questionText: 'Security Question',
        ),
      );
      return <String, dynamic>{
        'found': true,
        'hasQuestion': true,
        'question': question.questionText,
        'questionId': user.securityQuestionId,
      };
    } catch (e) {
      _errorMessage = 'Failed to load reset challenge: $e';
      notifyListeners();
      return null;
    }
  }

  /// Verifies the user's security answer and resets their password. Works
  /// for any active account (does not require an authenticated session).
  Future<bool> verifySecurityAnswer(String username, String answer) async {
    try {
      final maps = await _db.query(
        'users',
        where: 'username = ? AND is_active = ?',
        whereArgs: [username, 1],
        limit: 1,
      );
      if (maps.isEmpty) {
        _errorMessage = 'Account not found.';
        notifyListeners();
        return false;
      }

      final user = User.fromMap(maps.first);
      final salt = user.securityAnswerSalt;
      bool valid = false;
      if (salt != null && salt.isNotEmpty && user.securityAnswerHash != null) {
        valid = _crypto.verifyAnswer(answer, salt, user.securityAnswerHash!);
      } else if (user.securityAnswerHash != null) {
        valid = _legacyHash(answer) == user.securityAnswerHash;
      }

      if (!valid) {
        _errorMessage = 'Incorrect answer.';
        notifyListeners();
        return false;
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to verify answer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPasswordViaSecurityQuestion(
    String username,
    String answer,
    String newPassword,
  ) async {
    if (newPassword.length < 4) {
      _errorMessage = 'New password must be at least 4 characters.';
      notifyListeners();
      return false;
    }

    try {
      final maps = await _db.query(
        'users',
        where: 'username = ? AND is_active = ?',
        whereArgs: [username, 1],
        limit: 1,
      );
      if (maps.isEmpty) {
        _errorMessage = 'Account not found.';
        notifyListeners();
        return false;
      }

      final user = User.fromMap(maps.first);
      final salt = user.securityAnswerSalt;
      bool valid = false;
      if (salt != null && salt.isNotEmpty && user.securityAnswerHash != null) {
        valid = _crypto.verifyAnswer(answer, salt, user.securityAnswerHash!);
      } else if (user.securityAnswerHash != null) {
        valid = _legacyHash(answer) == user.securityAnswerHash;
      }

      if (!valid) {
        _errorMessage = 'Incorrect answer.';
        notifyListeners();
        return false;
      }

      final newSalt = _crypto.generateSalt();
      final newHash = _crypto.hashPassword(newPassword, newSalt);
      await _db.update('users', {
        'password_hash': newHash,
        'password_salt': newSalt,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: user.id!);

      _logSecurityEvent(
        'password_reset',
        'Password reset via security question for $username',
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reset password: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setPin(String newPin) async {
    if (_currentUser == null) return false;
    if (newPin.length < 4 || newPin.length > 6) {
      _errorMessage = 'PIN must be 4-6 digits.';
      return false;
    }

    try {
      final salt = _crypto.generateSalt();
      final pinHash = _crypto.hashPin(newPin, salt);
      await _db.update('users', {
        'pin_hash': pinHash,
        'pin_salt': salt,
        'pin': null,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: _currentUser!.id!);

      _currentUser = _currentUser!.copyWith(pinHash: pinHash, pinSalt: salt, pin: null);
      _logSecurityEvent('pin_changed', 'PIN was updated');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update PIN: $e';
      return false;
    }
  }

  Future<bool> setPattern(String pattern) async {
    if (_currentUser == null) return false;
    if (pattern.length < 4) {
      _errorMessage = 'Pattern must connect at least 4 dots.';
      return false;
    }

    try {
      final salt = _crypto.generateSalt();
      final patternHash = _crypto.hashPattern(pattern, salt);
      await _db.update('users', {
        'pattern_hash': patternHash,
        'pattern_salt': salt,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: _currentUser!.id!);

      _currentUser = _currentUser!.copyWith(patternHash: patternHash, patternSalt: salt);
      _logSecurityEvent('pattern_changed', 'Pattern lock was updated');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update pattern: $e';
      return false;
    }
  }

  Future<bool> setSecurityQuestion(int questionId, String answer) async {
    if (_currentUser == null) return false;

    try {
      final salt = _crypto.generateSalt();
      final answerHash = _crypto.hashAnswer(answer, salt);
      await _db.update('users', {
        'security_question_id': questionId,
        'security_answer_hash': answerHash,
        'security_answer_salt': salt,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: _currentUser!.id!);

      _currentUser = _currentUser!.copyWith(securityQuestionId: questionId, securityAnswerHash: answerHash, securityAnswerSalt: salt);
      _logSecurityEvent('security_question_set', 'Security question was set');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to set security question: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setLockType(String lockType) async {
    if (_currentUser == null) return false;

    try {
      await _db.update('users', {
        'lock_type': lockType,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: _currentUser!.id!);

      _currentUser = _currentUser!.copyWith(lockType: lockType);
      _logSecurityEvent('lock_type_set', 'Lock type was set to $lockType');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to set lock type: $e';
      notifyListeners();
      return false;
    }
  }

  Future<List<SecurityQuestion>> getSecurityQuestions() async {
    try {
      final maps = await _db.query('security_questions', orderBy: 'id');
      return maps.map((m) => SecurityQuestion.fromMap(m)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load security questions: $e';
      notifyListeners();
      return [];
    }
  }

  Future<String?> getCurrentUserSecurityQuestionText() async {
    if (_currentUser == null || _currentUser!.securityQuestionId == null) return null;
    try {
      final maps = await _db.query(
        'security_questions',
        where: 'id = ?',
        whereArgs: [_currentUser!.securityQuestionId],
        limit: 1,
      );
      if (maps.isNotEmpty) return maps.first['question_text'] as String;
    } catch (e) {
      _errorMessage = 'Failed to load security question: $e';
      notifyListeners();
    }
    return null;
  }

  Future<List<SecurityQuestion>> getRandomSecurityQuestions(int count) async {
    try {
      final all = await getSecurityQuestions();
      if (all.length <= count) return all;
      final shuffled = List<SecurityQuestion>.from(all);
      shuffled.shuffle();
      return shuffled.take(count).toList();
    } catch (e) {
      _errorMessage = 'Failed to load questions: $e';
      notifyListeners();
      return [];
    }
  }

  Future<bool> completeSecuritySetup({
    required String username,
    required String password,
    String? displayName,
    int? securityQuestionId,
    String? securityAnswer,
  }) async {
    try {
      final salt = _crypto.generateSalt();
      final passwordHash = _crypto.hashPassword(password, salt);
      final now = DateTime.now().toIso8601String();
      
      String? answerHash;
      String? answerSalt;
      if (securityAnswer != null && securityAnswer.isNotEmpty && securityQuestionId != null) {
        answerSalt = _crypto.generateSalt();
        answerHash = _crypto.hashAnswer(securityAnswer, answerSalt);
      }

      int id;
      try {
        id = await _db.insert('users', {
          'username': username,
          'password_hash': passwordHash,
          'password_salt': salt,
          'display_name': displayName ?? username,
          'email': null,
          'role': 'Admin',
          'is_active': 1,
          'setup_completed': 1,
          'lock_type': 'password',
          'security_question_id': securityQuestionId,
          'security_answer_hash': answerHash,
          'security_answer_salt': answerSalt,
          'created_at': now,
          'updated_at': now,
        });
      } catch (e) {
        final message = e.toString().toLowerCase();
        if (message.contains('unique constraint')) {
          _errorMessage = 'Username already exists. Please choose a different username.';
        } else {
          _errorMessage = 'Failed to complete setup: $e';
        }
        notifyListeners();
        return false;
      }

      _currentUser = User(
        id: id,
        username: username,
        passwordHash: passwordHash,
        passwordSalt: salt,
        displayName: displayName ?? username,
        email: null,
        role: 'Admin',
        isActive: true,
        setupCompleted: true,
        lockType: 'password',
        securityQuestionId: securityQuestionId,
        securityAnswerHash: answerHash,
        securityAnswerSalt: answerSalt,
      );

      _isSetupComplete = true;
      _isFirstRun = false;
      _isAuthenticated = true;
      _isSessionLocked = false;
      _lastActivity = DateTime.now();
      await _startup.setAccountCreated(true);
      await _startup.setUserId(id);
      _logSecurityEvent('security_setup', 'Initial security setup completed for user $username');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete setup: $e';
      return false;
    }
  }

  void lockSession() {
    if (!_isAuthenticated) return;
    _isSessionLocked = true;
    _lastActivity = DateTime.now();
    _logSecurityEvent('session_locked', 'Session was locked manually');
    notifyListeners();
  }

  Future<bool> unlockSession(String credential, {required String type}) async {
    if (type == 'password') {
      return await authenticateWithPassword(credential);
    } else if (type == 'pin') {
      return await authenticateWithPin(credential);
    } else if (type == 'pattern') {
      return await authenticateWithPattern(credential);
    }
    return false;
  }

  Future<void> logout() async {
    _logSecurityEvent('logout', 'User logged out');
    await _startup.logout();
    _currentUser = null;
    _isAuthenticated = false;
    _isSessionLocked = false;
    _failedAttempts = 0;
    _lockedUntil = null;
    _lastActivity = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    notifyListeners();
  }

  Future<void> _logSecurityEvent(String eventType, String details) async {
    try {
      await _db.insert('security_events', {
        'user_id': _currentUser?.id,
        'event_type': eventType,
        'details': details,
        'ip_address': kIsWeb ? 'web' : 'local',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // silent fail for logging
    }
  }

  String _hashPattern(String pattern) {
    final bytes = pattern.codeUnits;
    final hash = <int>[];
    for (var i = 0; i < bytes.length; i++) {
      hash.add((bytes[i] + i * 3) % 256);
    }
    return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _hashAnswer(String answer) {
    final normalized = answer.trim().toLowerCase();
    final bytes = normalized.codeUnits;
    final hash = <int>[];
    for (var i = 0; i < bytes.length; i++) {
      hash.add((bytes[i] + i * 5) % 256);
    }
    return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _legacyHash(String input) {
    final bytes = input.codeUnits;
    final hash = <int>[];
    for (var i = 0; i < bytes.length; i++) {
      hash.add((bytes[i] + i * 7) % 256);
    }
    return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _upgradePinHash(String pin) async {
    if (_currentUser == null) return;
    final salt = _crypto.generateSalt();
    final pinHash = _crypto.hashPin(pin, salt);
      await _db.update('users', {
        'pin_hash': pinHash,
        'pin_salt': salt,
        'pin': null,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: _currentUser!.id!);

      _currentUser = _currentUser!.copyWith(pinHash: pinHash, pinSalt: salt, pin: null);
  }

  Future<void> _upgradePatternHash(String pattern) async {
    if (_currentUser == null) return;
    final salt = _crypto.generateSalt();
    final patternHash = _crypto.hashPattern(pattern, salt);
    await _db.update('users', {
      'pattern_hash': patternHash,
      'pattern_salt': salt,
      'updated_at': DateTime.now().toIso8601String(),
    }, id: _currentUser!.id!);
    _currentUser = _currentUser!.copyWith(patternHash: patternHash, patternSalt: salt);
  }

  Future<void> _upgradeSecurityAnswerHash(String answer) async {
    if (_currentUser == null) return;
    final salt = _crypto.generateSalt();
    final answerHash = _crypto.hashAnswer(answer, salt);
    await _db.update('users', {
      'security_answer_hash': answerHash,
      'security_answer_salt': salt,
      'updated_at': DateTime.now().toIso8601String(),
    }, id: _currentUser!.id!);
    _currentUser = _currentUser!.copyWith(securityAnswerHash: answerHash, securityAnswerSalt: salt);
  }

  int _getRemainingLockoutMinutes() {
    if (_lockedUntil == null) return 0;
    final remaining = _lockedUntil!.difference(DateTime.now()).inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  Future<List<User>> getUsers() async {
    try {
      final maps = await _db.query('users', orderBy: 'display_name');
      return maps.map((m) => User.fromMap(m)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load users: $e';
      notifyListeners();
      return [];
    }
  }

  Future<bool> createUser(User user) async {
    try {
      final _ = await _db.insert('users', user.toMap());
      _logSecurityEvent('user_created', 'User ${user.username} was created');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create user: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      await _db.update('users', user.toMap(), id: user.id!);
      if (_currentUser?.id == user.id) {
        _currentUser = user;
      }
      _logSecurityEvent('user_updated', 'User ${user.username} was updated');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update user: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      await _db.delete('users', id: userId);
      if (_currentUser?.id == userId) {
        await logout();
      }
      _logSecurityEvent('user_deleted', 'User ID $userId was deleted');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete user: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetUserPassword(int userId, String newPassword) async {
    try {
      final salt = _crypto.generateSalt();
      final newHash = _crypto.hashPassword(newPassword, salt);
      await _db.update('users', {
        'password_hash': newHash,
        'password_salt': salt,
        'updated_at': DateTime.now().toIso8601String(),
      }, id: userId);
      _logSecurityEvent('password_reset_admin', 'Password was reset by admin for user ID $userId');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reset password: $e';
      notifyListeners();
      return false;
    }
  }

  Future<String> hashPassword(String password) async {
    final salt = _crypto.generateSalt();
    return _crypto.hashPassword(password, salt);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
