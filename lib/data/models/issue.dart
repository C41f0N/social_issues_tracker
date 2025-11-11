class Issue {
  String id;
  String? title, description;
  String? postedBy;
  int? upvoteCount, commentCount;

  bool loaded = false;

  Issue({required this.id});
}
