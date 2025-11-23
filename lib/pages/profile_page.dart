import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/auth/auth_notifier.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/role.dart';
import 'package:social_issues_tracker/pages/request_role_change_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _pendingRequest;
  bool _loadingRequest = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequest();
  }

  Future<void> _loadPendingRequest() async {
    final local = Provider.of<LocalData>(context, listen: false);
    final requests = await local.getMyRoleChangeRequests();

    // Find the most recent pending request
    final pending = requests.where((r) => r['status'] == 'pending').toList();

    setState(() {
      _pendingRequest = pending.isNotEmpty ? pending.first : null;
      _loadingRequest = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthNotifier>(context);
    final local = Provider.of<LocalData>(context);

    // Get user info from auth
    String displayName = 'Anonymous';
    String email = '';
    String username = '';
    String roleTitle = 'Citizen';

    if (auth.user != null) {
      displayName = auth.user!.fullName;
      email = auth.user!.email;
      username = auth.user!.username;
    }

    // Try to get role title from LocalData if available
    if (local.storedRoles.isNotEmpty && auth.user != null) {
      final r = local.storedRoles.firstWhere(
        (role) => role.id == auth.user!.roleId,
        orElse: () => Role(id: '1', title: 'Citizen'),
      );
      roleTitle = r.title ?? 'Citizen';
    }

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                child: Text(displayName.isNotEmpty ? displayName[0] : '?'),
              ),
              SizedBox(height: 15),
              Text(
                displayName,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              SizedBox(height: 10),
              Text(
                '@$username',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: 30),

              // Email
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email),
                  SizedBox(width: 10),
                  Text(email, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),

              SizedBox(height: 15),

              // Role
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 10),
                  Text(
                    roleTitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Pending Role Request Badge
              if (_loadingRequest)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_pendingRequest != null)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pending_actions,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pending Role Change Request',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Requesting: ${_pendingRequest!['requested_role']}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Submitted: ${_formatDate(_pendingRequest!['submitted_at'])}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Request Role Change Button
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RequestRoleChangePage(),
                    ),
                  );
                  // Reload pending request after returning
                  _loadPendingRequest();
                },
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Request Role Change'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),

              SizedBox(height: 50),

              LogoutButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  LogoutButton({super.key});

  final borderRadius = BorderRadius.circular(20);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final auth = Provider.of<AuthNotifier>(context, listen: false);
        await auth.logout();
        // AuthGate at root will rebuild automatically.
      },
      borderRadius: borderRadius,
      child: Container(
        width: 150,
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: borderRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout),
            SizedBox(width: 10),
            Container(
              color: Theme.of(context).colorScheme.onError,
              width: 1,
              height: 30,
            ),
            SizedBox(width: 10),
            Text("Logout"),
          ],
        ),
      ),
    );
  }
}
