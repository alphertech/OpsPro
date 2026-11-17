class Project {
  int? id;
  String name;
  String? description;
  int? customerId;
  String? customerName;
  DateTime startDate;
  DateTime? endDate;
  String status;
  double budget;
  double actualCost;
  int? managerId;
  String? managerName;
  String priority;
  int progress;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  Project({
    this.id,
    required this.name,
    this.description,
    this.customerId,
    this.customerName,
    DateTime? startDate,
    this.endDate,
    this.status = 'Planning',
    this.budget = 0,
    this.actualCost = 0,
    this.managerId,
    this.managerName,
    this.priority = 'Medium',
    this.progress = 0,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : startDate = startDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'customer_id': customerId,
      'customer_name': customerName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'budget': budget,
      'actual_cost': actualCost,
      'manager_id': managerId,
      'manager_name': managerName,
      'priority': priority,
      'progress': progress,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      status: map['status'] ?? 'Planning',
      budget: map['budget'] ?? 0,
      actualCost: map['actual_cost'] ?? 0,
      managerId: map['manager_id'],
      managerName: map['manager_name'],
      priority: map['priority'] ?? 'Medium',
      progress: map['progress'] ?? 0,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Project copyWith({
    int? id,
    String? name,
    String? description,
    int? customerId,
    String? customerName,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    double? budget,
    double? actualCost,
    int? managerId,
    String? managerName,
    String? priority,
    int? progress,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      actualCost: actualCost ?? this.actualCost,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProjectTask {
  int? id;
  int projectId;
  String projectName;
  String title;
  String? description;
  String status;
  String priority;
  DateTime? startDate;
  DateTime? dueDate;
  DateTime? completedDate;
  int? assignedTo;
  String? assigneeName;
  int? predecessorId;
  double estimatedHours;
  double actualHours;
  int progress;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  ProjectTask({
    this.id,
    required this.projectId,
    this.projectName = '',
    required this.title,
    this.description,
    this.status = 'Not Started',
    this.priority = 'Medium',
    this.startDate,
    this.dueDate,
    this.completedDate,
    this.assignedTo,
    this.assigneeName,
    this.predecessorId,
    this.estimatedHours = 0,
    this.actualHours = 0,
    this.progress = 0,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isCompleted => status == 'Completed';
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'project_name': projectName,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'start_date': startDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'assigned_to': assignedTo,
      'assignee_name': assigneeName,
      'predecessor_id': predecessorId,
      'estimated_hours': estimatedHours,
      'actual_hours': actualHours,
      'progress': progress,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProjectTask.fromMap(Map<String, dynamic> map) {
    return ProjectTask(
      id: map['id'],
      projectId: map['project_id'],
      projectName: map['project_name'] ?? '',
      title: map['title'],
      description: map['description'],
      status: map['status'] ?? 'Not Started',
      priority: map['priority'] ?? 'Medium',
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : null,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      completedDate: map['completed_date'] != null ? DateTime.parse(map['completed_date']) : null,
      assignedTo: map['assigned_to'],
      assigneeName: map['assignee_name'],
      predecessorId: map['predecessor_id'],
      estimatedHours: map['estimated_hours'] ?? 0,
      actualHours: map['actual_hours'] ?? 0,
      progress: map['progress'] ?? 0,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class TimeEntry {
  int? id;
  int? projectId;
  int? taskId;
  int? employeeId;
  String? employeeName;
  DateTime entryDate;
  double hours;
  String? description;
  bool isBillable;
  double? hourlyRate;
  DateTime createdAt;

  TimeEntry({
    this.id,
    this.projectId,
    this.taskId,
    this.employeeId,
    this.employeeName,
    DateTime? entryDate,
    required this.hours,
    this.description,
    this.isBillable = false,
    this.hourlyRate,
    DateTime? createdAt,
  })  : entryDate = entryDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  double get totalAmount => isBillable && hourlyRate != null ? hours * hourlyRate! : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'task_id': taskId,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'entry_date': entryDate.toIso8601String(),
      'hours': hours,
      'description': description,
      'is_billable': isBillable ? 1 : 0,
      'hourly_rate': hourlyRate,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      id: map['id'],
      projectId: map['project_id'],
      taskId: map['task_id'],
      employeeId: map['employee_id'],
      employeeName: map['employee_name'],
      entryDate: DateTime.parse(map['entry_date']),
      hours: map['hours'],
      description: map['description'],
      isBillable: map['is_billable'] == 1,
      hourlyRate: map['hourly_rate'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class ProjectAttachment {
  int? id;
  int projectId;
  String fileName;
  String filePath;
  double fileSize;
  String? description;
  DateTime createdAt;

  ProjectAttachment({
    this.id,
    required this.projectId,
    required this.fileName,
    required this.filePath,
    this.fileSize = 0,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProjectAttachment.fromMap(Map<String, dynamic> map) {
    return ProjectAttachment(
      id: map['id'],
      projectId: map['project_id'],
      fileName: map['file_name'],
      filePath: map['file_path'],
      fileSize: map['file_size'] ?? 0,
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
