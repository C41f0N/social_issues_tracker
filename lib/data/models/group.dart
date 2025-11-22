import 'dart:typed_data';

class Group {
  String id;
  String? title;
  String? description;
  String? postedBy;
  int? upvoteCount;
  int? commentCount;

  // IDs of issues contained in this group.
  List<String> issueIds = const [];

  // Image URL to load for this group (optional)
  String? imageUrl;

  // Raw image bytes once loaded; null until loaded.
  Uint8List? imageData;

  // Whether this group's image has been fully loaded.
  bool loaded = false;

  Group({
    required this.id,
    this.title,
    this.description,
    this.postedBy,
    this.upvoteCount,
    this.commentCount,
    this.imageUrl,
    List<String>? issueIds,
  }) : issueIds = issueIds ?? [];
}
