import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/auth/auth_notifier.dart';
import 'package:social_issues_tracker/data/local_data.dart';

class RequestRoleChangePage extends StatefulWidget {
  const RequestRoleChangePage({super.key});

  @override
  State<RequestRoleChangePage> createState() => _RequestRoleChangePageState();
}

class _RequestRoleChangePageState extends State<RequestRoleChangePage> {
  String? _selectedRoleId;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _myRequests = [];
  bool _loadingRequests = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final local = Provider.of<LocalData>(context, listen: false);

    // Fetch roles if not already loaded
    if (local.storedRoles.isEmpty) {
      await local.fetchRoles();
    }

    // Fetch user's existing requests
    final requests = await local.getMyRoleChangeRequests();

    setState(() {
      _myRequests = requests;
      _loadingRequests = false;
    });
  }

  Future<void> _submitRequest() async {
    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a role')));
      return;
    }

    setState(() => _isSubmitting = true);

    final local = Provider.of<LocalData>(context, listen: false);
    final success = await local.submitRoleChangeRequest(_selectedRoleId!);

    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role change request submitted successfully'),
          ),
        );
        // Reload requests
        _loadData();
        setState(() => _selectedRoleId = null);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to submit request. You may already have a pending request.',
            ),
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthNotifier>(context);
    final local = Provider.of<LocalData>(context);

    // Get current user role
    String currentRoleTitle = 'Citizen';
    if (local.storedRoles.isNotEmpty && auth.user != null) {
      final currentRole = local.storedRoles.firstWhere(
        (r) => r.id == auth.user!.roleId,
        orElse: () => local.storedRoles.first,
      );
      currentRoleTitle = currentRole.title ?? 'Citizen';
    }

    // Filter out current role from available options
    final availableRoles = local.storedRoles
        .where((r) => r.id != auth.user?.roleId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Request Role Change')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Role
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 40),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Role',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          currentRoleTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Request New Role
            Text(
              'Request New Role',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            if (local.storedRoles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (availableRoles.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No other roles available'),
                ),
              )
            else
              ...availableRoles.map(
                (role) => RadioListTile<String>(
                  title: Text(role.title ?? 'Unknown Role'),
                  value: role.id,
                  groupValue: _selectedRoleId,
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() => _selectedRoleId = value);
                        },
                ),
              ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || _selectedRoleId == null
                    ? null
                    : _submitRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Request'),
              ),
            ),

            const SizedBox(height: 32),

            // My Requests History
            Text(
              'Request History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            if (_loadingRequests)
              const Center(child: CircularProgressIndicator())
            else if (_myRequests.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No requests found'),
                ),
              )
            else
              ..._myRequests.map(
                (request) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(
                                request['status'].toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: _getStatusColor(
                                request['status'],
                              ),
                            ),
                            Text(
                              _formatDate(request['submitted_at']),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              request['current_role'] ?? 'Unknown',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward),
                            ),
                            Text(
                              request['requested_role'] ?? 'Unknown',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        if (request['reviewed_at'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Reviewed: ${_formatDate(request['reviewed_at'])}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
