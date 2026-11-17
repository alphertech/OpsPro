import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/security_provider.dart';
import '../../models/user.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/data_table_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/password_confirmation_dialog.dart';
import '../../utils/validators.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final users = await context.read<SecurityProvider>().getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return user.displayName.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: const CustomAppBar(title: 'User Management', showBackButton: true),
      drawer: const AppDrawer(currentRoute: '/settings/users'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'Search users',
                    hint: 'Name, username, or role',
                    prefixIcon: CupertinoIcons.search,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  label: 'Add User',
                  icon: CupertinoIcons.person_add,
                  onPressed: () => _addUser(context),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  isCompact: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${filteredUsers.length} users',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                            const SizedBox(height: 16),
                            Text(_errorMessage!, style: TextStyle(color: Colors.red[600])),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _loadUsers,
                              icon: const Icon(CupertinoIcons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('No users found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                              ],
                            ),
                          )
                        : DataTableWidget(
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Username')),
                              DataColumn(label: Text('Role')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Last Login')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: filteredUsers
                                .map(
                                  (user) => DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                              child: Text(
                                                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                                                style: TextStyle(
                                                  color: Theme.of(context).primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                user.displayName,
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(user.username)),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(user.role),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            user.role,
                                            style: TextStyle(fontSize: 11, color: _getRoleTextColor(user.role), fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: user.isActive ? Colors.green[100] : Colors.red[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            user.isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: user.isActive ? Colors.green[700] : Colors.red[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(user.lastLogin != null ? DateFormat('dd/MM/yyyy HH:mm').format(user.lastLogin!) : 'Never'),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                              tooltip: 'Edit',
                                              onPressed: () => _editUser(context, user),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.lock_reset, size: 18, color: Colors.orange),
                                              tooltip: 'Reset Password',
                                              onPressed: () => _resetPassword(context, user),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: Icon(user.isActive ? Icons.toggle_on : Icons.toggle_off, size: 18, color: user.isActive ? Colors.green : Colors.orange),
                                              tooltip: user.isActive ? 'Deactivate' : 'Activate',
                                              onPressed: () => _toggleUserStatus(context, user),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addUser(context),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(CupertinoIcons.person_add),
        label: const Text('Add User'),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red.withValues(alpha: 0.1);
      case 'manager':
        return Colors.blue.withValues(alpha: 0.1);
      case 'cashier':
        return Colors.green.withValues(alpha: 0.1);
      default:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }

  Color _getRoleTextColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.blue;
      case 'cashier':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _addUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _UserFormDialog(onUserSaved: _loadUsers),
    );
  }

  void _editUser(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => _UserFormDialog(user: user, onUserSaved: _loadUsers),
    );
  }

  void _resetPassword(BuildContext context, User user) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Reset Password - ${user.displayName}')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter new password for this user:'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: passwordController,
              label: 'New Password',
              obscureText: true,
              validator: (value) => Validators.required(value, 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.trim().isEmpty) return;
              final securityProvider = context.read<SecurityProvider>();
              final confirmed = await PasswordConfirmationDialog.show(context);
              if (!confirmed || !context.mounted) return;

              final success = await securityProvider.resetUserPassword(user.id!, passwordController.text.trim());
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset successfully'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(BuildContext context, User user) async {
    final securityProvider = context.read<SecurityProvider>();
    final confirmed = await PasswordConfirmationDialog.show(context);
    if (!confirmed || !mounted) return;

    final updatedUser = user.copyWith(isActive: !user.isActive);
    final success = await securityProvider.updateUser(updatedUser);
    if (success && context.mounted) {
      setState(() {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) _users[index] = updatedUser;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${user.isActive ? 'deactivated' : 'activated'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _UserFormDialog extends StatefulWidget {
  final User? user;
  final VoidCallback onUserSaved;

  const _UserFormDialog({this.user, required this.onUserSaved});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'Cashier';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _populateFields(widget.user!);
    }
  }

  void _populateFields(User user) {
    _displayNameController.text = user.displayName;
    _usernameController.text = user.username;
    _emailController.text = user.email ?? '';
    _role = user.role;
    _isActive = user.isActive;
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await PasswordConfirmationDialog.show(context);
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final user = User(
        id: widget.user?.id,
        username: _usernameController.text.trim(),
        passwordHash: widget.user?.passwordHash ?? '',
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        role: _role,
        isActive: _isActive,
        lastLogin: widget.user?.lastLogin,
        createdAt: widget.user?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = widget.user == null
          ? await context.read<SecurityProvider>().createUser(user)
          : await context.read<SecurityProvider>().updateUser(user);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.user == null ? 'User created successfully!' : 'User updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUserSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(widget.user == null ? 'Add User' : 'Edit User')),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _displayNameController,
                  label: 'Full Name *',
                  validator: (value) => Validators.required(value, 'Full name'),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _usernameController,
                  label: 'Username *',
                  validator: (value) => Validators.required(value, 'Username'),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Optional',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                if (widget.user == null)
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password *',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                if (widget.user == null) const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'Cashier', child: Text('Cashier')),
                  ],
                  onChanged: (value) => setState(() => _role = value!),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveUser,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
