import 'package:flutter/material.dart';
import 'package:social_issues_tracker/data/models/user.dart';
import 'package:social_issues_tracker/constants.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius});

  final User? user;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;

    if (user != null) {
      debugPrint(user!.imageUrl);
      if (user!.imageData != null) {
        imageProvider = MemoryImage(user!.imageData!);
      } else if (user!.imageUrl != null && user!.imageUrl!.isNotEmpty) {
        // imageUrl may already be a full URL, but getFullImageUrl is safe
        imageProvider = NetworkImage(getFullImageUrl(user!.imageUrl));
      }
    }

    return CircleAvatar(
      radius: radius,
      foregroundImage: imageProvider,
      child: imageProvider == null && user != null
          ? Text(
              user!.name != null && user!.name!.isNotEmpty
                  ? user!.name![0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: radius != null ? radius! * 0.6 : null,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
