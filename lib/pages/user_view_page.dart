import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/user.dart';
import 'package:social_issues_tracker/widgets/user_avatar.dart';
import 'package:social_issues_tracker/widgets/with_custom_header.dart';

class UserViewPage extends StatefulWidget {
  const UserViewPage({super.key, required this.userId});

  final String userId;

  @override
  State<UserViewPage> createState() => _UserViewPageState();
}

class _UserViewPageState extends State<UserViewPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LocalData>(
      builder: (context, local, child) {
        User? user = local.getUserById(widget.userId);

        return Scaffold(
          body: WithCustomHeader(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UserAvatar(user: user, radius: 60),

                  SizedBox(height: 25),

                  Text(
                    user.name ?? "Loading...",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),

                  SizedBox(height: 5),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      local.getRoleById(user.role!) != null
                          ? local.getRoleById(user.role!).title ?? "Loading..."
                          : "Loading...",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
