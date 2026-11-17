class SecurityQuestion {
  final int? id;
  final String questionText;
  final bool isDefault;
  final DateTime createdAt;

  SecurityQuestion({
    this.id,
    required this.questionText,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_text': questionText,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SecurityQuestion.fromMap(Map<String, dynamic> map) {
    return SecurityQuestion(
      id: map['id'],
      questionText: map['question_text'],
      isDefault: map['is_default'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class SecurityEvent {
  final int? id;
  final int? userId;
  final String eventType;
  final String? details;
  final String? ipAddress;
  final DateTime createdAt;

  SecurityEvent({
    this.id,
    this.userId,
    required this.eventType,
    this.details,
    this.ipAddress,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'event_type': eventType,
      'details': details,
      'ip_address': ipAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SecurityEvent.fromMap(Map<String, dynamic> map) {
    return SecurityEvent(
      id: map['id'],
      userId: map['user_id'],
      eventType: map['event_type'],
      details: map['details'],
      ipAddress: map['ip_address'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class SecuritySettings {
  final int maxFailedAttempts;
  final int lockoutDurationMinutes;
  final bool requireSecurityQuestion;
  final bool allowPattern;
  final bool allowPin;
  final bool allowPassword;
  final int sessionTimeoutMinutes;
  final bool enableF5Lock;

  const SecuritySettings({
    this.maxFailedAttempts = 5,
    this.lockoutDurationMinutes = 15,
    this.requireSecurityQuestion = true,
    this.allowPattern = true,
    this.allowPin = true,
    this.allowPassword = true,
    this.sessionTimeoutMinutes = 15,
    this.enableF5Lock = true,
  });

  SecuritySettings copyWith({
    int? maxFailedAttempts,
    int? lockoutDurationMinutes,
    bool? requireSecurityQuestion,
    bool? allowPattern,
    bool? allowPin,
    bool? allowPassword,
    int? sessionTimeoutMinutes,
    bool? enableF5Lock,
  }) {
    return SecuritySettings(
      maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
      lockoutDurationMinutes: lockoutDurationMinutes ?? this.lockoutDurationMinutes,
      requireSecurityQuestion: requireSecurityQuestion ?? this.requireSecurityQuestion,
      allowPattern: allowPattern ?? this.allowPattern,
      allowPin: allowPin ?? this.allowPin,
      allowPassword: allowPassword ?? this.allowPassword,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      enableF5Lock: enableF5Lock ?? this.enableF5Lock,
    );
  }
}

class SecurityConfig {
  final int? id;
  final int maxFailedAttempts;
  final int lockoutDurationMinutes;
  final bool requireSecurityQuestion;
  final bool allowPattern;
  final bool allowPin;
  final bool allowPassword;
  final int sessionTimeoutMinutes;
  final bool enableF5Lock;
  final DateTime updatedAt;

  SecurityConfig({
    this.id,
    this.maxFailedAttempts = 5,
    this.lockoutDurationMinutes = 15,
    this.requireSecurityQuestion = true,
    this.allowPattern = true,
    this.allowPin = true,
    this.allowPassword = true,
    this.sessionTimeoutMinutes = 15,
    this.enableF5Lock = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'max_failed_attempts': maxFailedAttempts,
      'lockout_duration_minutes': lockoutDurationMinutes,
      'require_security_question': requireSecurityQuestion ? 1 : 0,
      'allow_pattern': allowPattern ? 1 : 0,
      'allow_pin': allowPin ? 1 : 0,
      'allow_password': allowPassword ? 1 : 0,
      'session_timeout_minutes': sessionTimeoutMinutes,
      'enable_f5_lock': enableF5Lock ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SecurityConfig.fromMap(Map<String, dynamic> map) {
    return SecurityConfig(
      id: map['id'],
      maxFailedAttempts: map['max_failed_attempts'] ?? 5,
      lockoutDurationMinutes: map['lockout_duration_minutes'] ?? 15,
      requireSecurityQuestion: map['require_security_question'] == 1,
      allowPattern: map['allow_pattern'] == 1,
      allowPin: map['allow_pin'] == 1,
      allowPassword: map['allow_password'] == 1,
      sessionTimeoutMinutes: map['session_timeout_minutes'] ?? 15,
      enableF5Lock: map['enable_f5_lock'] == 1,
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  SecuritySettings toSettings() {
    return SecuritySettings(
      maxFailedAttempts: maxFailedAttempts,
      lockoutDurationMinutes: lockoutDurationMinutes,
      requireSecurityQuestion: requireSecurityQuestion,
      allowPattern: allowPattern,
      allowPin: allowPin,
      allowPassword: allowPassword,
      sessionTimeoutMinutes: sessionTimeoutMinutes,
      enableF5Lock: enableF5Lock,
    );
  }
}
