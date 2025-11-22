import 'dart:typed_data';

class User {
  String id;
  String? name;
  String? role;

  // Optional profile image URL and bytes
  String? imageUrl;
  Uint8List? imageData;

  // Whether the user's profile image has been loaded
  bool loaded = false;

  User({
    required this.id,
    this.name,
    this.role,
    this.imageUrl,
  });
}
