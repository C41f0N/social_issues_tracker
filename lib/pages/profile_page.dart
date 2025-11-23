import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/auth/auth_notifier.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/role.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              child: Text(displayName.isNotEmpty ? displayName[0] : '?'),
            ),
            SizedBox(height: 15),
            Text(displayName, style: Theme.of(context).textTheme.displaySmall),
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
                Text(roleTitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),

            SizedBox(height: 100),

            LogoutButton(),
          ],
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
