import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/auth/auth_notifier.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/user.dart';
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

    // Prefer user metadata from auth, then fallback to local seeded users
    String displayName = 'Anonymous';
    String email = '';
    String roleTitle = 'Citizen';

    if (auth.user != null) {
      final meta = auth.user!.userMetadata ?? {};
      displayName =
          (meta['full_name'] as String?) ??
          (meta['username'] as String?) ??
          auth.user!.id;
      email = auth.user!.email ?? '';
    }

    // Try to enrich from LocalData if available
    if (local.storedUsers.isNotEmpty && auth.user != null) {
      final found = local.storedUsers.firstWhere(
        (u) => u.id == auth.user!.id,
        orElse: () => User(id: auth.user!.id, name: displayName),
      );
      displayName = (found.name != null && found.name!.isNotEmpty)
          ? found.name!
          : displayName;
      // local roles use short ids; default to Citizen when unknown
      final r = local.storedRoles.firstWhere(
        (role) => role.id == (found.role ?? ''),
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
            SizedBox(height: 30),

            // Email
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email),
                SizedBox(width: 10),
                Text(
                  email.isNotEmpty ? email : 'No email',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
