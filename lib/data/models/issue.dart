import 'dart:typed_data';

class Issue {
  String id;
  String? title;
  String? description;
  String? postedBy; // user_id from backend
  int? upvoteCount;
  int? commentCount;
  // IDs of comments associated with this issue. Stored in LocalData.storedComments.
  List<String> commentIds = const [];
  // IDs of files attached to this issue. Stored in LocalData.storedFiles.
  List<String> fileIds = const [];

  // Backend fields
  DateTime? postedAt; // posted_at from backend
  String? groupId; // group_id from backend
  String? displayPictureUrl; // display_picture_url from backend
  List<Map<String, dynamic>> attachments = const []; // attachments from backend

  // Image URL to load for this issue (optional)
  String? imageUrl;

  // Raw image bytes once loaded; null until loaded.
  Uint8List? imageData;

  // Whether this issue's data (image) has been fully loaded.
  bool loaded = false;

  // Whether full issue details have been fetched (for lazy loading)
  bool fullyLoaded = false;

  Issue({
    required this.id,
    this.title,
    this.description,
    this.postedBy,
    this.upvoteCount,
    this.commentCount,
    this.imageUrl,
    this.postedAt,
    this.groupId,
    this.displayPictureUrl,
    List<String>? commentIds,
    List<String>? fileIds,
    List<Map<String, dynamic>>? attachments,
  }) : commentIds = commentIds ?? [],
       fileIds = fileIds ?? [],
       attachments = attachments ?? [];
}
