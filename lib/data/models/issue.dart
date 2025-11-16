import 'dart:typed_data';

class Issue {
  String id;
  String? title;
  String? description;
  String? postedBy;
  int? upvoteCount;
  int? commentCount;

  // Image URL to load for this issue (optional)
  String? imageUrl;

  // Raw image bytes once loaded; null until loaded.
  Uint8List? imageData;

  // Whether this issue's data (image) has been fully loaded.
  bool loaded = false;

  Issue({
    required this.id,
    this.title,
    this.description,
    this.postedBy,
    this.upvoteCount,
    this.commentCount,
    this.imageUrl,
  });
}
