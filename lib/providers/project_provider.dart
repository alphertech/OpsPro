import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../services/database_service.dart';

class ProjectProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Project> _projects = [];
  List<ProjectTask> _tasks = [];
  List<TimeEntry> _timeEntries = [];
  List<ProjectAttachment> _attachments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Project> get projects => _projects;
  List<ProjectTask> get tasks => _tasks;
  List<TimeEntry> get timeEntries => _timeEntries;
  List<ProjectAttachment> get attachments => _attachments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Project> get activeProjects => _projects.where((p) => p.status != 'Completed' && p.status != 'Cancelled').toList();
  List<Project> get completedProjects => _projects.where((p) => p.status == 'Completed').toList();
  List<ProjectTask> get pendingTasks => _tasks.where((t) => t.status != 'Completed').toList();
  List<ProjectTask> get overdueTasks => _tasks.where((t) => t.isOverdue).toList();

  Future<void> loadProjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final maps = await Future.microtask(() async {
        return await _db.query('projects', orderBy: 'created_at DESC');
      });
      _projects = maps.map((map) => Project.fromMap(map)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load projects: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTasks(int projectId) async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('project_tasks', where: 'project_id = ?', whereArgs: [projectId], orderBy: 'due_date');
      });
      _tasks = maps.map((map) => ProjectTask.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load tasks: $e';
      notifyListeners();
    }
  }

  Future<void> loadTimeEntries({int? projectId, int? employeeId}) async {
    try {
      String? where;
      List<dynamic>? whereArgs;

      if (projectId != null && employeeId != null) {
        where = 'project_id = ? AND employee_id = ?';
        whereArgs = [projectId, employeeId];
      } else if (projectId != null) {
        where = 'project_id = ?';
        whereArgs = [projectId];
      } else if (employeeId != null) {
        where = 'employee_id = ?';
        whereArgs = [employeeId];
      }

      final maps = await Future.microtask(() async {
        return await _db.query('time_entries', where: where, whereArgs: whereArgs, orderBy: 'entry_date DESC');
      });
      _timeEntries = maps.map((map) => TimeEntry.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load time entries: $e';
      notifyListeners();
    }
  }

  Future<void> loadAttachments(int projectId) async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('project_attachments', where: 'project_id = ?', whereArgs: [projectId]);
      });
      _attachments = maps.map((map) => ProjectAttachment.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load attachments: $e';
      notifyListeners();
    }
  }

  Future<bool> createProject(Project project) async {
    try {
      final id = await _db.insert('projects', project.toMap());
      _projects.insert(0, Project(
        id: id,
        name: project.name,
        description: project.description,
        customerId: project.customerId,
        customerName: project.customerName,
        startDate: project.startDate,
        endDate: project.endDate,
        status: project.status,
        budget: project.budget,
        actualCost: project.actualCost,
        managerId: project.managerId,
        managerName: project.managerName,
        priority: project.priority,
        progress: project.progress,
        notes: project.notes,
        createdAt: project.createdAt,
        updatedAt: project.updatedAt,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create project: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProject(Project project) async {
    try {
      await _db.update('projects', project.toMap(), id: project.id!);
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _projects[index] = project;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update project: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProject(int projectId) async {
    try {
      await _db.delete('projects', id: projectId);
      _projects.removeWhere((p) => p.id == projectId);
      _tasks.removeWhere((t) => t.projectId == projectId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete project: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createTask(ProjectTask task) async {
    try {
      final id = await _db.insert('project_tasks', task.toMap());
      _tasks.add(ProjectTask(
        id: id,
        projectId: task.projectId,
        projectName: task.projectName,
        title: task.title,
        description: task.description,
        status: task.status,
        priority: task.priority,
        startDate: task.startDate,
        dueDate: task.dueDate,
        completedDate: task.completedDate,
        assignedTo: task.assignedTo,
        assigneeName: task.assigneeName,
        predecessorId: task.predecessorId,
        estimatedHours: task.estimatedHours,
        actualHours: task.actualHours,
        progress: task.progress,
        notes: task.notes,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
      ));
      await _updateProjectProgress(task.projectId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create task: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(ProjectTask task) async {
    try {
      await _db.update('project_tasks', task.toMap(), id: task.id!);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      }
      await _updateProjectProgress(task.projectId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update task: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTask(int taskId) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final task = _tasks[index];
        final completedTask = ProjectTask(
          id: task.id,
          projectId: task.projectId,
          projectName: task.projectName,
          title: task.title,
          description: task.description,
          status: 'Completed',
          priority: task.priority,
          startDate: task.startDate,
          dueDate: task.dueDate,
          completedDate: DateTime.now(),
          assignedTo: task.assignedTo,
          assigneeName: task.assigneeName,
          predecessorId: task.predecessorId,
          estimatedHours: task.estimatedHours,
          actualHours: task.actualHours,
          progress: 100,
          notes: task.notes,
          createdAt: task.createdAt,
          updatedAt: DateTime.now(),
        );

        await _db.update('project_tasks', completedTask.toMap(), id: taskId);
        _tasks[index] = completedTask;
        await _updateProjectProgress(task.projectId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to complete task: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(int taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      await _db.delete('project_tasks', id: taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      await _updateProjectProgress(task.projectId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete task: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addTimeEntry(TimeEntry entry) async {
    try {
      final id = await _db.insert('time_entries', entry.toMap());
      _timeEntries.insert(0, TimeEntry(
        id: id,
        projectId: entry.projectId,
        taskId: entry.taskId,
        employeeId: entry.employeeId,
        employeeName: entry.employeeName,
        entryDate: entry.entryDate,
        hours: entry.hours,
        description: entry.description,
        isBillable: entry.isBillable,
        hourlyRate: entry.hourlyRate,
        createdAt: entry.createdAt,
      ));

      if (entry.taskId != null) {
        final taskIndex = _tasks.indexWhere((t) => t.id == entry.taskId);
        if (taskIndex != -1) {
          final task = _tasks[taskIndex];
          final updatedTask = ProjectTask(
            id: task.id,
            projectId: task.projectId,
            projectName: task.projectName,
            title: task.title,
            description: task.description,
            status: task.status,
            priority: task.priority,
            startDate: task.startDate,
            dueDate: task.dueDate,
            completedDate: task.completedDate,
            assignedTo: task.assignedTo,
            assigneeName: task.assigneeName,
            predecessorId: task.predecessorId,
            estimatedHours: task.estimatedHours,
            actualHours: task.actualHours + entry.hours,
            progress: task.progress,
            notes: task.notes,
            createdAt: task.createdAt,
            updatedAt: DateTime.now(),
          );
          await _db.update('project_tasks', updatedTask.toMap(), id: task.id!);
          _tasks[taskIndex] = updatedTask;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add time entry: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addAttachment(ProjectAttachment attachment) async {
    try {
      final id = await _db.insert('project_attachments', attachment.toMap());
      _attachments.add(ProjectAttachment(
        id: id,
        projectId: attachment.projectId,
        fileName: attachment.fileName,
        filePath: attachment.filePath,
        fileSize: attachment.fileSize,
        description: attachment.description,
        createdAt: attachment.createdAt,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add attachment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _updateProjectProgress(int projectId) async {
    final projectTasks = _tasks.where((t) => t.projectId == projectId).toList();
    if (projectTasks.isNotEmpty) {
      final completedTasks = projectTasks.where((t) => t.status == 'Completed').length;
      final progress = ((completedTasks / projectTasks.length) * 100).round();

      final projectIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final updatedProject = _projects[projectIndex].copyWith(
          progress: progress,
          status: progress == 100 ? 'Completed' : _projects[projectIndex].status,
        );
        _projects[projectIndex] = updatedProject;
        await _db.update('projects', updatedProject.toMap(), id: projectId);
      }
    }
  }

  Project? getProjectById(int id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ProjectTask> getTasksForProject(int projectId) {
    return _tasks.where((t) => t.projectId == projectId).toList();
  }

  double getTotalHoursForProject(int projectId) {
    return _timeEntries
        .where((e) => e.projectId == projectId)
        .fold(0.0, (sum, e) => sum + e.hours);
  }

  double getTotalBillableForProject(int projectId) {
    return _timeEntries
        .where((e) => e.projectId == projectId && e.isBillable)
        .fold(0.0, (sum, e) => sum + (e.hourlyRate ?? 0) * e.hours);
  }
}
