import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../services/database_service.dart';

class EmployeeProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Employee> _employees = [];
  List<LeaveRequest> _leaveRequests = [];
  List<Shift> _shifts = [];
  List<ExpenseReimbursement> _reimbursements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Employee> get employees => _employees;
  List<LeaveRequest> get leaveRequests => _leaveRequests;
  List<Shift> get shifts => _shifts;
  List<ExpenseReimbursement> get reimbursements => _reimbursements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Employee> get activeEmployees => _employees.where((e) => e.isActive && e.status == 'Active').toList();
  List<LeaveRequest> get pendingLeaves => _leaveRequests.where((l) => l.status == 'Pending').toList();
  List<ExpenseReimbursement> get pendingReimbursements => _reimbursements.where((r) => r.status == 'Pending').toList();

  Future<void> loadEmployees() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final maps = await Future.microtask(() async {
        return await _db.query('employees', orderBy: 'first_name');
      });
      _employees = maps.map((map) => Employee.fromMap(map)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load employees: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaveRequests() async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('leave_requests', orderBy: 'created_at DESC');
      });
      _leaveRequests = maps.map((map) => LeaveRequest.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load leave requests: $e';
      notifyListeners();
    }
  }

  Future<void> loadShifts() async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('shifts', orderBy: 'shift_date DESC');
      });
      _shifts = maps.map((map) => Shift.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load shifts: $e';
      notifyListeners();
    }
  }

  Future<void> loadReimbursements() async {
    try {
      final maps = await Future.microtask(() async {
        return await _db.query('expense_reimbursements', orderBy: 'created_at DESC');
      });
      _reimbursements = maps.map((map) => ExpenseReimbursement.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load reimbursements: $e';
      notifyListeners();
    }
  }

  Future<bool> createEmployee(Employee employee) async {
    try {
      final id = await _db.insert('employees', employee.toMap());
      final newEmployee = Employee(
        id: id,
        employeeId: employee.employeeId,
        firstName: employee.firstName,
        lastName: employee.lastName,
        email: employee.email,
        phone: employee.phone,
        address: employee.address,
        idNumber: employee.idNumber,
        taxId: employee.taxId,
        emergencyContactName: employee.emergencyContactName,
        emergencyContactPhone: employee.emergencyContactPhone,
        jobTitle: employee.jobTitle,
        department: employee.department,
        hireDate: employee.hireDate,
        salary: employee.salary,
        employmentType: employee.employmentType,
        status: employee.status,
        terminationDate: employee.terminationDate,
        bankName: employee.bankName,
        bankAccountNumber: employee.bankAccountNumber,
        notes: employee.notes,
        isActive: employee.isActive,
        createdAt: employee.createdAt,
        updatedAt: employee.updatedAt,
      );
      _employees.add(newEmployee);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create employee: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmployee(Employee employee) async {
    try {
      await _db.update('employees', employee.toMap(), id: employee.id!);
      final index = _employees.indexWhere((e) => e.id == employee.id);
      if (index != -1) {
        _employees[index] = employee;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update employee: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEmployee(int employeeId) async {
    try {
      await _db.update('employees', {'is_active': 0}, id: employeeId);
      final index = _employees.indexWhere((e) => e.id == employeeId);
      if (index != -1) {
        _employees[index] = _employees[index].copyWith(isActive: false);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete employee: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createLeaveRequest(LeaveRequest leave) async {
    try {
      final id = await _db.insert('leave_requests', leave.toMap());
      _leaveRequests.insert(0, LeaveRequest(
        id: id,
        employeeId: leave.employeeId,
        employeeName: leave.employeeName,
        leaveType: leave.leaveType,
        startDate: leave.startDate,
        endDate: leave.endDate,
        days: leave.days,
        reason: leave.reason,
        status: leave.status,
        approvedBy: leave.approvedBy,
        approverName: leave.approverName,
        approvedAt: leave.approvedAt,
        comments: leave.comments,
        createdAt: leave.createdAt,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create leave request: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveLeaveRequest(int leaveId, int approverId, String approverName, String? comments) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _db.update('leave_requests', {
        'status': 'Approved',
        'approved_by': approverId,
        'approver_name': approverName,
        'approved_at': now,
        'comments': comments,
      }, id: leaveId);

      final index = _leaveRequests.indexWhere((l) => l.id == leaveId);
      if (index != -1) {
        _leaveRequests[index] = LeaveRequest(
          id: _leaveRequests[index].id,
          employeeId: _leaveRequests[index].employeeId,
          employeeName: _leaveRequests[index].employeeName,
          leaveType: _leaveRequests[index].leaveType,
          startDate: _leaveRequests[index].startDate,
          endDate: _leaveRequests[index].endDate,
          days: _leaveRequests[index].days,
          reason: _leaveRequests[index].reason,
          status: 'Approved',
          approvedBy: approverId,
          approverName: approverName,
          approvedAt: DateTime.now(),
          comments: comments,
          createdAt: _leaveRequests[index].createdAt,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to approve leave: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectLeaveRequest(int leaveId, int approverId, String approverName, String? comments) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _db.update('leave_requests', {
        'status': 'Rejected',
        'approved_by': approverId,
        'approver_name': approverName,
        'approved_at': now,
        'comments': comments,
      }, id: leaveId);

      final index = _leaveRequests.indexWhere((l) => l.id == leaveId);
      if (index != -1) {
        _leaveRequests[index] = LeaveRequest(
          id: _leaveRequests[index].id,
          employeeId: _leaveRequests[index].employeeId,
          employeeName: _leaveRequests[index].employeeName,
          leaveType: _leaveRequests[index].leaveType,
          startDate: _leaveRequests[index].startDate,
          endDate: _leaveRequests[index].endDate,
          days: _leaveRequests[index].days,
          reason: _leaveRequests[index].reason,
          status: 'Rejected',
          approvedBy: approverId,
          approverName: approverName,
          approvedAt: DateTime.now(),
          comments: comments,
          createdAt: _leaveRequests[index].createdAt,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reject leave: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createShift(Shift shift) async {
    try {
      final id = await _db.insert('shifts', shift.toMap());
      _shifts.insert(0, Shift(
        id: id,
        employeeId: shift.employeeId,
        employeeName: shift.employeeName,
        shiftDate: shift.shiftDate,
        startTime: shift.startTime,
        endTime: shift.endTime,
        breakDuration: shift.breakDuration,
        shiftType: shift.shiftType,
        notes: shift.notes,
        createdAt: shift.createdAt,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create shift: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteShift(int shiftId) async {
    try {
      await _db.delete('shifts', id: shiftId);
      _shifts.removeWhere((s) => s.id == shiftId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete shift: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createReimbursement(ExpenseReimbursement reimbursement) async {
    try {
      final id = await _db.insert('expense_reimbursements', reimbursement.toMap());
      _reimbursements.insert(0, ExpenseReimbursement(
        id: id,
        employeeId: reimbursement.employeeId,
        employeeName: reimbursement.employeeName,
        expenseDate: reimbursement.expenseDate,
        category: reimbursement.category,
        amount: reimbursement.amount,
        description: reimbursement.description,
        receiptPath: reimbursement.receiptPath,
        status: reimbursement.status,
        approvedBy: reimbursement.approvedBy,
        approverName: reimbursement.approverName,
        approvedAt: reimbursement.approvedAt,
        notes: reimbursement.notes,
        createdAt: reimbursement.createdAt,
      ));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create reimbursement: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveReimbursement(int reimbursementId, int approverId, String approverName) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _db.update('expense_reimbursements', {
        'status': 'Approved',
        'approved_by': approverId,
        'approver_name': approverName,
        'approved_at': now,
      }, id: reimbursementId);

      final index = _reimbursements.indexWhere((r) => r.id == reimbursementId);
      if (index != -1) {
        _reimbursements[index] = ExpenseReimbursement(
          id: _reimbursements[index].id,
          employeeId: _reimbursements[index].employeeId,
          employeeName: _reimbursements[index].employeeName,
          expenseDate: _reimbursements[index].expenseDate,
          category: _reimbursements[index].category,
          amount: _reimbursements[index].amount,
          description: _reimbursements[index].description,
          receiptPath: _reimbursements[index].receiptPath,
          status: 'Approved',
          approvedBy: approverId,
          approverName: approverName,
          approvedAt: DateTime.now(),
          notes: _reimbursements[index].notes,
          createdAt: _reimbursements[index].createdAt,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to approve reimbursement: $e';
      notifyListeners();
      return false;
    }
  }

  Employee? getEmployeeById(int id) {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Shift> getShiftsForDate(DateTime date) {
    return _shifts.where((s) {
      return s.shiftDate.year == date.year &&
          s.shiftDate.month == date.month &&
          s.shiftDate.day == date.day;
    }).toList();
  }

  List<Shift> getShiftsForEmployee(int employeeId) {
    return _shifts.where((s) => s.employeeId == employeeId).toList();
  }
}
