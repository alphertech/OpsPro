import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';
import '../../models/employee.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _idNumberController;
  late TextEditingController _jobTitleController;
  late TextEditingController _departmentController;
  late TextEditingController _salaryController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankAccountController;
  String _employmentType = 'Full-time';
  DateTime _hireDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.employee?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.employee?.lastName ?? '');
    _emailController = TextEditingController(text: widget.employee?.email ?? '');
    _phoneController = TextEditingController(text: widget.employee?.phone ?? '');
    _addressController = TextEditingController(text: widget.employee?.address ?? '');
    _idNumberController = TextEditingController(text: widget.employee?.idNumber ?? '');
    _jobTitleController = TextEditingController(text: widget.employee?.jobTitle ?? '');
    _departmentController = TextEditingController(text: widget.employee?.department ?? '');
    _salaryController = TextEditingController(text: widget.employee?.salary.toString() ?? '0');
    _bankNameController = TextEditingController(text: widget.employee?.bankName ?? '');
    _bankAccountController = TextEditingController(text: widget.employee?.bankAccountNumber ?? '');
    if (widget.employee != null) {
      _employmentType = widget.employee!.employmentType;
      _hireDate = widget.employee!.hireDate;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _idNumberController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _salaryController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerRight,
            child: const Text(
              'Plexus',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/hr/employees/add'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idNumberController,
                decoration: const InputDecoration(labelText: 'ID Number'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _jobTitleController,
                      decoration: const InputDecoration(labelText: 'Job Title'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(labelText: 'Department'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryController,
                      decoration: const InputDecoration(labelText: 'Salary'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _employmentType,
                      decoration: const InputDecoration(labelText: 'Employment Type'),
                      items: ['Full-time', 'Part-time', 'Contract', 'Intern']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _employmentType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bankNameController,
                      decoration: const InputDecoration(labelText: 'Bank Name'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _bankAccountController,
                      decoration: const InputDecoration(labelText: 'Bank Account'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEmployee,
                  child: Text(widget.employee == null ? 'Add Employee' : 'Update Employee'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      final confirmed = await PasswordConfirmationDialog.show(context);
      if (!confirmed || !mounted) return;

      final employee = Employee(
        id: widget.employee?.id,
        employeeId: widget.employee?.employeeId ?? 'EMP${DateTime.now().millisecondsSinceEpoch}',
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        idNumber: _idNumberController.text.isNotEmpty ? _idNumberController.text : null,
        jobTitle: _jobTitleController.text,
        department: _departmentController.text,
        hireDate: _hireDate,
        salary: double.tryParse(_salaryController.text) ?? 0,
        employmentType: _employmentType,
        bankName: _bankNameController.text.isNotEmpty ? _bankNameController.text : null,
        bankAccountNumber: _bankAccountController.text.isNotEmpty ? _bankAccountController.text : null,
        isActive: widget.employee?.isActive ?? true,
      );

      final provider = context.read<EmployeeProvider>();
      bool success;
      if (widget.employee == null) {
        success = await provider.createEmployee(employee);
      } else {
        success = await provider.updateEmployee(employee);
      }

      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }
}

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EmployeeProvider>();
      provider.loadLeaveRequests();
      provider.loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddLeaveDialog(context),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerRight,
            child: const Text(
              'Plexus',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/hr/leave'),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, _) {
          if (provider.leaveRequests.isEmpty) {
            return const Center(child: Text('No leave requests'));
          }

          return ListView.builder(
            itemCount: provider.leaveRequests.length,
            itemBuilder: (context, index) {
              final leave = provider.leaveRequests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    leave.status == 'Approved'
                        ? Icons.check_circle
                        : leave.status == 'Rejected'
                            ? Icons.cancel
                            : Icons.pending,
                    color: leave.status == 'Approved'
                        ? Colors.green
                        : leave.status == 'Rejected'
                            ? Colors.red
                            : Colors.orange,
                  ),
                  title: Text('${leave.employeeName} - ${leave.leaveType}'),
                  subtitle: Text('${leave.startDate.toString().split(' ')[0]} to ${leave.endDate.toString().split(' ')[0]} (${leave.days} days)'),
                  trailing: leave.status == 'Pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                final confirmed = await PasswordConfirmationDialog.show(context);
                                if (!confirmed) return;
                                provider.approveLeaveRequest(leave.id!, 1, 'Admin', null);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                final confirmed = await PasswordConfirmationDialog.show(context);
                                if (!confirmed) return;
                                provider.rejectLeaveRequest(leave.id!, 1, 'Admin', null);
                              },
                            ),
                          ],
                        )
                      : Text(leave.status),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddLeaveDialog(BuildContext context) {
    final provider = context.read<EmployeeProvider>();
    final reasonController = TextEditingController();
    final daysController = TextEditingController();
    int? employeeId;
    String leaveType = 'Annual';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('New Leave Request'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: employeeId,
                decoration: const InputDecoration(labelText: 'Employee'),
                items: provider.activeEmployees
                    .map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName)))
                    .toList(),
                onChanged: (v) => employeeId = v,
              ),
              DropdownButtonFormField<String>(
                initialValue: leaveType,
                decoration: const InputDecoration(labelText: 'Leave Type'),
                items: ['Annual', 'Sick', 'Personal', 'Maternity', 'Paternity', 'Unpaid']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => leaveType = v!,
              ),
              TextField(
                controller: daysController,
                decoration: const InputDecoration(labelText: 'Days'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (employeeId != null) {
                final confirmed = await PasswordConfirmationDialog.show(context);
                if (!confirmed) return;

                final employee = provider.getEmployeeById(employeeId!);
                await provider.createLeaveRequest(LeaveRequest(
                  employeeId: employeeId!,
                  employeeName: employee?.fullName ?? '',
                  leaveType: leaveType,
                  days: double.tryParse(daysController.text) ?? 1,
                  reason: reasonController.text,
                ));
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class ShiftScheduleScreen extends StatefulWidget {
  const ShiftScheduleScreen({super.key});

  @override
  State<ShiftScheduleScreen> createState() => _ShiftScheduleScreenState();
}

class _ShiftScheduleScreenState extends State<ShiftScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EmployeeProvider>();
      provider.loadShifts();
      provider.loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Schedule'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddShiftDialog(context),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerRight,
            child: const Text(
              'Plexus',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/hr/shifts'),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, _) {
          final shifts = provider.getShiftsForDate(_selectedDate);

          return Column(
            children: [
              ListTile(
                title: const Text('Selected Date'),
                subtitle: Text(_selectedDate.toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              const Divider(),
              Expanded(
                child: shifts.isEmpty
                    ? const Center(child: Text('No shifts for this date'))
                    : ListView.builder(
                        itemCount: shifts.length,
                        itemBuilder: (context, index) {
                          final shift = shifts[index];
                          return ListTile(
                            title: Text(shift.employeeName),
                            subtitle: Text('${shift.startTime} - ${shift.endTime}'),
                            trailing: Text(shift.shiftType),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddShiftDialog(BuildContext context) {
    final provider = context.read<EmployeeProvider>();
    int? employeeId;
    String startTime = '08:00';
    String endTime = '17:00';
    String shiftType = 'Regular';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Add Shift'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: employeeId,
                decoration: const InputDecoration(labelText: 'Employee'),
                items: provider.activeEmployees
                    .map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName)))
                    .toList(),
                onChanged: (v) => employeeId = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Start Time'),
                controller: TextEditingController(text: startTime),
                onChanged: (v) => startTime = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'End Time'),
                controller: TextEditingController(text: endTime),
                onChanged: (v) => endTime = v,
              ),
              DropdownButtonFormField<String>(
                initialValue: shiftType,
                decoration: const InputDecoration(labelText: 'Shift Type'),
                items: ['Regular', 'Overtime', 'Night', 'Weekend', 'Holiday']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => shiftType = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (employeeId != null) {
                final confirmed = await PasswordConfirmationDialog.show(context);
                if (!confirmed) return;

                final employee = provider.getEmployeeById(employeeId!);
                await provider.createShift(Shift(
                  employeeId: employeeId!,
                  employeeName: employee?.fullName ?? '',
                  shiftDate: _selectedDate,
                  startTime: startTime,
                  endTime: endTime,
                  shiftType: shiftType,
                ));
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class ExpenseReimbursementScreen extends StatefulWidget {
  const ExpenseReimbursementScreen({super.key});

  @override
  State<ExpenseReimbursementScreen> createState() => _ExpenseReimbursementScreenState();
}

class _ExpenseReimbursementScreenState extends State<ExpenseReimbursementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EmployeeProvider>();
      provider.loadReimbursements();
      provider.loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Reimbursements'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddReimbursementDialog(context),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerRight,
            child: const Text(
              'Plexus',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/hr/reimbursements'),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, _) {
          if (provider.reimbursements.isEmpty) {
            return const Center(child: Text('No reimbursement requests'));
          }

          return ListView.builder(
            itemCount: provider.reimbursements.length,
            itemBuilder: (context, index) {
              final r = provider.reimbursements[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    r.status == 'Approved'
                        ? Icons.check_circle
                        : r.status == 'Rejected'
                            ? Icons.cancel
                            : Icons.pending,
                    color: r.status == 'Approved'
                        ? Colors.green
                        : r.status == 'Rejected'
                            ? Colors.red
                            : Colors.orange,
                  ),
                  title: Text('${r.employeeName} - ${r.category}'),
                  subtitle: Text(r.description),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('UGX ${r.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (r.status == 'Pending')
                        TextButton(
                          onPressed: () async {
                            final confirmed = await PasswordConfirmationDialog.show(context);
                            if (!confirmed) return;
                            provider.approveReimbursement(r.id!, 1, 'Admin');
                          },
                          child: const Text('Approve'),
                        )
                      else
                        Text(r.status),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddReimbursementDialog(BuildContext context) {
    final provider = context.read<EmployeeProvider>();
    final descController = TextEditingController();
    final amountController = TextEditingController();
    int? employeeId;
    String category = 'Transport';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('New Reimbursement'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: employeeId,
                decoration: const InputDecoration(labelText: 'Employee'),
                items: provider.activeEmployees
                    .map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName)))
                    .toList(),
                onChanged: (v) => employeeId = v,
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Transport', 'Meals', 'Accommodation', 'Supplies', 'Communication', 'Other']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => category = v!,
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (employeeId != null) {
                final confirmed = await PasswordConfirmationDialog.show(context);
                if (!confirmed) return;

                final employee = provider.getEmployeeById(employeeId!);
                await provider.createReimbursement(ExpenseReimbursement(
                  employeeId: employeeId!,
                  employeeName: employee?.fullName ?? '',
                  category: category,
                  amount: double.tryParse(amountController.text) ?? 0,
                  description: descController.text,
                ));
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
