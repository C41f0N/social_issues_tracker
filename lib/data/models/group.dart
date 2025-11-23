import 'dart:typed_data';

class Group {
  String id;
  String? title;
  String? description;
  String? postedBy;
  int? upvoteCount;
  int? commentCount;

  // IDs of issues contained in this group.
  List<String>? issueIds;

  // IDs of comments on this group
  List<String>? commentIds;

  // IDs of files attached to this group. Stored in LocalData.storedFiles.
  List<String>? fileIds;

  // Display picture URL from backend
  String? displayPictureUrl;

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
    this.displayPictureUrl,
    this.issueIds,
    this.commentIds,
    this.fileIds,
  });
}
