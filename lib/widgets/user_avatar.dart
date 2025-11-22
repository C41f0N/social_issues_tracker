import 'package:flutter/material.dart';
import 'package:social_issues_tracker/data/models/user.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius});

  final User? user;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      foregroundImage: user != null && user!.imageData != null
          ? MemoryImage(user!.imageData!)
          : null,
    );
  }
}
