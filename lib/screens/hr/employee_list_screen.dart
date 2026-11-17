import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';
import '../../config/routes.dart';
import '../../services/navigation_service.dart';
import '../../widgets/app_drawer.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => NavigationService.navigateTo(AppRoutes.employeeAdd),
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
      drawer: const AppDrawer(currentRoute: '/hr/employees'),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.employees.isEmpty) {
            return const Center(child: Text('No employees yet'));
          }

          return ListView.builder(
            itemCount: provider.employees.length,
            itemBuilder: (context, index) {
              final employee = provider.employees[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: employee.isActive ? Colors.green : Colors.grey,
                    child: Text(employee.firstName[0]),
                  ),
                  title: Text(employee.fullName),
                  subtitle: Text('${employee.jobTitle} - ${employee.department}'),
                  trailing: Text(employee.status),
                  onTap: () => NavigationService.navigateTo(
                    AppRoutes.employeeEdit,
                    arguments: {'employee': employee},
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
