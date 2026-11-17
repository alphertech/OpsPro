class User {
  int? id;
  String username;
  String passwordHash;
  String? passwordSalt;
  String? pinHash;
  String? pinSalt;
  String? pin;
  String displayName;
  String? email;
  String role;
  bool isActive;
  DateTime? lastLogin;
  String? patternHash;
  String? patternSalt;
  int failedAttempts;
  DateTime? lockedUntil;
  int? securityQuestionId;
  String? securityAnswerHash;
  String? securityAnswerSalt;
  bool setupCompleted;
  String? lockType;
  int lockoutLevel;
  DateTime createdAt;
  DateTime updatedAt;

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    this.passwordSalt,
    this.pinHash,
    this.pinSalt,
    this.pin,
    required this.displayName,
    this.email,
    required this.role,
    this.isActive = true,
    this.lastLogin,
    this.patternHash,
    this.patternSalt,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.securityQuestionId,
    this.securityAnswerHash,
    this.securityAnswerSalt,
    this.setupCompleted = false,
    this.lockType,
    this.lockoutLevel = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'pin_hash': pinHash,
      'pin_salt': pinSalt,
      'display_name': displayName,
      'email': email,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'last_login': lastLogin?.toIso8601String(),
      'pattern_hash': patternHash,
      'pattern_salt': patternSalt,
      'failed_attempts': failedAttempts,
      'locked_until': lockedUntil?.toIso8601String(),
      'security_question_id': securityQuestionId,
      'security_answer_hash': securityAnswerHash,
      'security_answer_salt': securityAnswerSalt,
      'setup_completed': setupCompleted ? 1 : 0,
      'lock_type': lockType,
      'lockout_level': lockoutLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      passwordHash: map['password_hash'] ?? '',
      passwordSalt: map['password_salt'],
      pinHash: map['pin_hash'],
      pinSalt: map['pin_salt'],
      pin: map['pin'],
      displayName: map['display_name'],
      email: map['email'],
      role: map['role'],
      isActive: map['is_active'] == 1,
      lastLogin: map['last_login'] != null ? DateTime.parse(map['last_login']) : null,
      patternHash: map['pattern_hash'],
      patternSalt: map['pattern_salt'],
      failedAttempts: map['failed_attempts'] ?? 0,
      lockedUntil: map['locked_until'] != null ? DateTime.parse(map['locked_until']) : null,
      securityQuestionId: map['security_question_id'],
      securityAnswerHash: map['security_answer_hash'],
      securityAnswerSalt: map['security_answer_salt'],
      setupCompleted: map['setup_completed'] == 1,
      lockType: map['lock_type'],
      lockoutLevel: map['lockout_level'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? passwordSalt,
    String? pinHash,
    String? pinSalt,
    String? pin,
    String? displayName,
    String? email,
    String? role,
    bool? isActive,
    DateTime? lastLogin,
    String? patternHash,
    String? patternSalt,
    int? failedAttempts,
    DateTime? lockedUntil,
    int? securityQuestionId,
    String? securityAnswerHash,
    String? securityAnswerSalt,
    bool? setupCompleted,
    String? lockType,
    int? lockoutLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      pinHash: pinHash ?? this.pinHash,
      pinSalt: pinSalt ?? this.pinSalt,
      pin: pin ?? this.pin,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      patternHash: patternHash ?? this.patternHash,
      patternSalt: patternSalt ?? this.patternSalt,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      securityQuestionId: securityQuestionId ?? this.securityQuestionId,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
      securityAnswerSalt: securityAnswerSalt ?? this.securityAnswerSalt,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      lockType: lockType ?? this.lockType,
      lockoutLevel: lockoutLevel ?? this.lockoutLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
