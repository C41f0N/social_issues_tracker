import 'package:flutter/material.dart';
import 'package:social_issues_tracker/widgets/with_custom_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 60),
            SizedBox(height: 15),
            Text("John Doe", style: Theme.of(context).textTheme.displaySmall),
            SizedBox(height: 30),

            // Email
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email),
                SizedBox(width: 10),
                Text(
                  "email@email.com",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            SizedBox(height: 15),

            // Phone
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone),
                SizedBox(width: 10),
                Text(
                  "+92 309 2149209",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            SizedBox(height: 15),

            // Phone
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person),
                SizedBox(width: 10),
                Text("Citizen", style: Theme.of(context).textTheme.bodyMedium),
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
      onTap: () {},
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
