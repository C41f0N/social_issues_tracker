class Comment {
  String id;
  String issueId;
  String? postedBy;
  DateTime postedAt;
  String content;

  Comment({
    required this.id,
    required this.issueId,
    this.postedBy,
    DateTime? postedAt,
    this.content = '',
  }) : postedAt = postedAt ?? DateTime.now();
}
