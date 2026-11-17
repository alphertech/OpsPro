class Employee {
  int? id;
  String employeeId;
  String firstName;
  String lastName;
  String? email;
  String? phone;
  String? address;
  String? idNumber;
  String? taxId;
  String? emergencyContactName;
  String? emergencyContactPhone;
  String jobTitle;
  String department;
  DateTime hireDate;
  double salary;
  String employmentType;
  String status;
  DateTime? terminationDate;
  String? bankName;
  String? bankAccountNumber;
  String? notes;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  Employee({
    this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.address,
    this.idNumber,
    this.taxId,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.jobTitle,
    this.department = '',
    DateTime? hireDate,
    this.salary = 0,
    this.employmentType = 'Full-time',
    this.status = 'Active',
    this.terminationDate,
    this.bankName,
    this.bankAccountNumber,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : hireDate = hireDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'id_number': idNumber,
      'tax_id': taxId,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'job_title': jobTitle,
      'department': department,
      'hire_date': hireDate.toIso8601String(),
      'salary': salary,
      'employment_type': employmentType,
      'status': status,
      'termination_date': terminationDate?.toIso8601String(),
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      employeeId: map['employee_id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      idNumber: map['id_number'],
      taxId: map['tax_id'],
      emergencyContactName: map['emergency_contact_name'],
      emergencyContactPhone: map['emergency_contact_phone'],
      jobTitle: map['job_title'],
      department: map['department'] ?? '',
      hireDate: DateTime.parse(map['hire_date']),
      salary: map['salary'] ?? 0,
      employmentType: map['employment_type'] ?? 'Full-time',
      status: map['status'] ?? 'Active',
      terminationDate: map['termination_date'] != null ? DateTime.parse(map['termination_date']) : null,
      bankName: map['bank_name'],
      bankAccountNumber: map['bank_account_number'],
      notes: map['notes'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Employee copyWith({
    int? id,
    String? employeeId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    String? idNumber,
    String? taxId,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? jobTitle,
    String? department,
    DateTime? hireDate,
    double? salary,
    String? employmentType,
    String? status,
    DateTime? terminationDate,
    String? bankName,
    String? bankAccountNumber,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      idNumber: idNumber ?? this.idNumber,
      taxId: taxId ?? this.taxId,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      hireDate: hireDate ?? this.hireDate,
      salary: salary ?? this.salary,
      employmentType: employmentType ?? this.employmentType,
      status: status ?? this.status,
      terminationDate: terminationDate ?? this.terminationDate,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LeaveRequest {
  int? id;
  int employeeId;
  String employeeName;
  String leaveType;
  DateTime startDate;
  DateTime endDate;
  double days;
  String reason;
  String status;
  int? approvedBy;
  String? approverName;
  DateTime? approvedAt;
  String? comments;
  DateTime createdAt;

  LeaveRequest({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    DateTime? startDate,
    DateTime? endDate,
    this.days = 0,
    required this.reason,
    this.status = 'Pending',
    this.approvedBy,
    this.approverName,
    this.approvedAt,
    this.comments,
    DateTime? createdAt,
  })  : startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'days': days,
      'reason': reason,
      'status': status,
      'approved_by': approvedBy,
      'approver_name': approverName,
      'approved_at': approvedAt?.toIso8601String(),
      'comments': comments,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    return LeaveRequest(
      id: map['id'],
      employeeId: map['employee_id'],
      employeeName: map['employee_name'],
      leaveType: map['leave_type'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      days: map['days'] ?? 0,
      reason: map['reason'],
      status: map['status'] ?? 'Pending',
      approvedBy: map['approved_by'],
      approverName: map['approver_name'],
      approvedAt: map['approved_at'] != null ? DateTime.parse(map['approved_at']) : null,
      comments: map['comments'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class Shift {
  int? id;
  int employeeId;
  String employeeName;
  DateTime shiftDate;
  String startTime;
  String endTime;
  String? breakDuration;
  String shiftType;
  String? notes;
  DateTime createdAt;

  Shift({
    this.id,
    required this.employeeId,
    required this.employeeName,
    DateTime? shiftDate,
    required this.startTime,
    required this.endTime,
    this.breakDuration,
    this.shiftType = 'Regular',
    this.notes,
    DateTime? createdAt,
  })  : shiftDate = shiftDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'shift_date': shiftDate.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'break_duration': breakDuration,
      'shift_type': shiftType,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'],
      employeeId: map['employee_id'],
      employeeName: map['employee_name'],
      shiftDate: DateTime.parse(map['shift_date']),
      startTime: map['start_time'],
      endTime: map['end_time'],
      breakDuration: map['break_duration'],
      shiftType: map['shift_type'] ?? 'Regular',
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class ExpenseReimbursement {
  int? id;
  int employeeId;
  String employeeName;
  DateTime expenseDate;
  String category;
  double amount;
  String description;
  String? receiptPath;
  String status;
  int? approvedBy;
  String? approverName;
  DateTime? approvedAt;
  String? notes;
  DateTime createdAt;

  ExpenseReimbursement({
    this.id,
    required this.employeeId,
    required this.employeeName,
    DateTime? expenseDate,
    required this.category,
    required this.amount,
    required this.description,
    this.receiptPath,
    this.status = 'Pending',
    this.approvedBy,
    this.approverName,
    this.approvedAt,
    this.notes,
    DateTime? createdAt,
  })  : expenseDate = expenseDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'expense_date': expenseDate.toIso8601String(),
      'category': category,
      'amount': amount,
      'description': description,
      'receipt_path': receiptPath,
      'status': status,
      'approved_by': approvedBy,
      'approver_name': approverName,
      'approved_at': approvedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseReimbursement.fromMap(Map<String, dynamic> map) {
    return ExpenseReimbursement(
      id: map['id'],
      employeeId: map['employee_id'],
      employeeName: map['employee_name'],
      expenseDate: DateTime.parse(map['expense_date']),
      category: map['category'],
      amount: map['amount'],
      description: map['description'],
      receiptPath: map['receipt_path'],
      status: map['status'] ?? 'Pending',
      approvedBy: map['approved_by'],
      approverName: map['approver_name'],
      approvedAt: map['approved_at'] != null ? DateTime.parse(map['approved_at']) : null,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
