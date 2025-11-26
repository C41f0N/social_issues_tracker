import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

// Backend API URL
const String apiBaseUrl = 'http://localhost:3000';

// Helper to convert relative paths to full URLs
String getFullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path; // Already a full URL
  }
  // Remove leading slash if present to avoid double slashes
  final cleanPath = path.startsWith('/') ? path.substring(1) : path;
  return '$apiBaseUrl/$cleanPath';
}

IconData upvoteIconFilled = EvaIcons.arrow_up;
IconData upvoteIconOutlined = EvaIcons.arrow_up_outline;

Widget upvoteIcon(bool isUpvoted) {
  return Transform.scale(
    scale: 1.7,
    child: Icon(isUpvoted ? upvoteIconFilled : upvoteIconOutlined),
  );
}
