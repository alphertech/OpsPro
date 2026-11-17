import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/project.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';

class ProjectFormScreen extends StatefulWidget {
  final Project? project;

  const ProjectFormScreen({super.key, this.project});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _budgetController;
  late TextEditingController _notesController;
  int? _customerId;
  DateTime _startDate = DateTime.now();
  String _status = 'Planning';
  String _priority = 'Medium';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descController = TextEditingController(text: widget.project?.description ?? '');
    _budgetController = TextEditingController(text: widget.project?.budget.toString() ?? '0');
    _notesController = TextEditingController(text: widget.project?.notes ?? '');
    if (widget.project != null) {
      _customerId = widget.project!.customerId;
      _startDate = widget.project!.startDate;
      _status = widget.project!.status;
      _priority = widget.project!.priority;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? 'New Project' : 'Edit Project'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProject,
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
      drawer: const AppDrawer(currentRoute: '/projects/add'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Consumer<CustomerProvider>(
                builder: (context, customerProvider, _) {
                  return DropdownButtonFormField<int>(
                    initialValue: _customerId,
                    decoration: const InputDecoration(labelText: 'Customer (Optional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...customerProvider.customers
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => setState(() => _customerId = v),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _budgetController,
                      decoration: const InputDecoration(labelText: 'Budget'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: ['Low', 'Medium', 'High', 'Critical']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Planning', 'In Progress', 'On Hold', 'Completed', 'Cancelled']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProject,
                  child: Text(widget.project == null ? 'Create Project' : 'Update Project'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProject() async {
    if (_formKey.currentState!.validate()) {
      final confirmed = await PasswordConfirmationDialog.show(context);
      if (!confirmed || !mounted) return;

      final customerProvider = context.read<CustomerProvider>();
      final customer = _customerId != null
          ? customerProvider.customers.firstWhere((c) => c.id == _customerId, orElse: () => customerProvider.customers.first)
          : null;

      final project = Project(
        id: widget.project?.id,
        name: _nameController.text,
        description: _descController.text.isNotEmpty ? _descController.text : null,
        customerId: _customerId,
        customerName: customer?.name,
        startDate: _startDate,
        status: _status,
        priority: _priority,
        budget: double.tryParse(_budgetController.text) ?? 0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final provider = context.read<ProjectProvider>();
      bool success;
      if (widget.project == null) {
        success = await provider.createProject(project);
      } else {
        success = await provider.updateProject(project);
      }

      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }
}

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProjectProvider>();
      provider.loadTasks(widget.projectId);
      provider.loadTimeEntries(projectId: widget.projectId);
      provider.loadAttachments(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTaskDialog(context),
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
      drawer: const AppDrawer(currentRoute: '/projects/detail'),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final project = provider.getProjectById(widget.projectId);
          if (project == null) {
            return const Center(child: Text('Project not found'));
          }

          final tasks = provider.getTasksForProject(widget.projectId);
          final totalHours = provider.getTotalHoursForProject(widget.projectId);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProjectHeader(project, totalHours),
                const SizedBox(height: 24),
                _buildTasksList(tasks, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectHeader(Project project, double totalHours) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.name, style: Theme.of(context).textTheme.headlineSmall),
            if (project.description != null) ...[
              const SizedBox(height: 8),
              Text(project.description!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip('Status', project.status),
                const SizedBox(width: 8),
                _buildInfoChip('Priority', project.priority),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: project.progress / 100),
            const SizedBox(height: 8),
            Text('Progress: ${project.progress}%'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget: UGX ${project.budget.toStringAsFixed(0)}'),
                Text('Hours: ${totalHours.toStringAsFixed(1)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.grey.shade200,
    );
  }

  Widget _buildTasksList(List<ProjectTask> tasks, ProjectProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No tasks yet'),
          ))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    color: task.isCompleted ? Colors.green : Colors.grey,
                  ),
                  title: Text(task.title),
                  subtitle: Text('${task.status} - Due: ${task.dueDate?.toString().split(' ')[0] ?? 'N/A'}'),
                          trailing: task.status != 'Completed'
                              ? IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () async {
                                    final confirmed = await PasswordConfirmationDialog.show(context);
                                    if (!confirmed || !mounted) return;
                                    provider.completeTask(task.id!);
                                  },
                                )
                              : null,
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final provider = context.read<ProjectProvider>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final hoursController = TextEditingController();
    String priority = 'Medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Add Task'),
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
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: hoursController,
                decoration: const InputDecoration(labelText: 'Estimated Hours'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['Low', 'Medium', 'High']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => priority = v!,
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
              await provider.createTask(ProjectTask(
                projectId: widget.projectId,
                projectName: provider.getProjectById(widget.projectId)?.name ?? '',
                title: titleController.text,
                description: descController.text.isNotEmpty ? descController.text : null,
                estimatedHours: double.tryParse(hoursController.text) ?? 0,
                priority: priority,
              ));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
