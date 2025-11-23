import 'package:flutter/material.dart';

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

IconData upvoteIconFilled = Icons.favorite;
IconData upvoteIconOutlined = Icons.favorite_border;
