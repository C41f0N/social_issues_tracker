import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:social_issues_tracker/data/models/issue.dart';
import 'package:social_issues_tracker/data/models/group.dart';
import 'package:social_issues_tracker/data/models/comment.dart';
import 'package:social_issues_tracker/data/models/user.dart';
import 'package:social_issues_tracker/data/models/role.dart';

// Lightweight descriptor for feed entries used by the homepage reel.
class FeedRef {
  final String id;
  final bool isGroup;
  FeedRef(this.id, this.isGroup);
}

class LocalData with ChangeNotifier {
  List<User> storedUsers = [
    User(
      id: "user1",
      name: "Sarim Ahmed",
      role: "1",
      imageUrl: 'https://api.dicebear.com/9.x/pixel-art/png?seed=Sarim%20Ahmed',
    ),
    User(
      id: "user2",
      name: "Aisha Khan",
      role: "2",
      imageUrl: 'https://api.dicebear.com/9.x/pixel-art/png?seed=Aisha%20Khan',
    ),
    User(
      id: "user3",
      name: "Daniel Park",
      role: "2",
      imageUrl: 'https://api.dicebear.com/9.x/pixel-art/png?seed=Daniel%20Park',
    ),
    User(
      id: "user4",
      name: "Maria Gomez",
      role: "3",
      imageUrl: 'https://api.dicebear.com/9.x/pixel-art/png?seed=Maria%20Gomez',
    ),
  ];

  // Stored roles (small lookup table)
  List<Role> storedRoles = [
    Role(id: '1', title: 'Citizen'),
    Role(id: '2', title: 'Lawyer'),
    Role(id: '3', title: 'Council Member'),
  ];

  List<Issue> storedIssues = [
    Issue(
      id: "issue1",
      title: "Lack of street lighting",
      description:
          "Several streets in the north end are poorly lit at night causing safety concerns.",
      upvoteCount: 24123,
      commentCount: 4,
      postedBy: "user2",
      commentIds: ['c_issue1_1', 'c_issue1_2', 'c_issue1_3', 'c_issue1_4'],
      imageUrl: 'https://picsum.photos/id/1015/800/1200',
    ),
    Issue(
      id: "issue2",
      title: "Overflowing trash bins",
      description:
          "Public bins near the market overflow every weekend and attract pests.",
      upvoteCount: 15,
      commentCount: 3,
      postedBy: "user1",
      commentIds: ['c_issue2_1', 'c_issue2_2', 'c_issue2_3'],
      imageUrl: 'https://picsum.photos/id/1025/800/1200',
    ),
    Issue(
      id: "issue3",
      title: "Broken playground equipment",
      description:
          "The swings at Central Park are broken and pose a hazard to children.",
      upvoteCount: 32,
      commentCount: 4,
      postedBy: "user4",
      commentIds: ['c_issue3_1', 'c_issue3_2', 'c_issue3_3', 'c_issue3_4'],
      imageUrl: 'https://picsum.photos/id/1035/800/1200',
    ),
    Issue(
      id: "issue4",
      title: "Illegal parking on sidewalks",
      description:
          "Cars regularly block sidewalks, forcing pedestrians into the street.",
      upvoteCount: 18,
      commentCount: 2,
      postedBy: "user3",
      commentIds: ['c_issue4_1', 'c_issue4_2'],
      imageUrl: 'https://picsum.photos/id/1045/800/1200',
    ),
    Issue(
      id: "issue5",
      title: "Water supply interruptions",
      description: "Frequent water outages in Block C for the past two weeks.",
      upvoteCount: 40,
      commentCount: 3,
      postedBy: "user2",
      commentIds: ['c_issue5_1', 'c_issue5_2', 'c_issue5_3'],
      imageUrl: 'https://picsum.photos/id/1055/800/1200',
    ),
    Issue(
      id: "issue6",
      title: "Graffiti on public buildings",
      description:
          "New graffiti has appeared on the library facade; needs cleaning.",
      upvoteCount: 9,
      commentCount: 2,
      postedBy: "user4",
      commentIds: ['c_issue6_1', 'c_issue6_2'],
      imageUrl: 'https://picsum.photos/id/1065/800/1200',
    ),
    Issue(
      id: "issue7",
      title: "No recycling pickup",
      description:
          "Recycling hasn't been collected in our area since last month.",
      upvoteCount: 22,
      commentCount: 2,
      postedBy: "user1",
      commentIds: ['c_issue7_1', 'c_issue7_2'],
      imageUrl: 'https://picsum.photos/id/1075/800/1200',
    ),
    Issue(
      id: "issue8",
      title: "Potholes on Main St.",
      description:
          "Multiple potholes causing damage to vehicles and slowing traffic.",
      upvoteCount: 55,
      commentCount: 3,
      postedBy: "user3",
      commentIds: ['c_issue8_1', 'c_issue8_2', 'c_issue8_3'],
      imageUrl: 'https://picsum.photos/id/1085/800/1200',
    ),
    Issue(
      id: "issue9",
      title: "Bus schedule inaccuracies",
      description:
          "The posted bus timetable is outdated and buses are often late.",
      upvoteCount: 13,
      commentCount: 2,
      postedBy: "user2",
      commentIds: ['c_issue9_1', 'c_issue9_2'],
      imageUrl: 'https://picsum.photos/id/1095/800/1200',
    ),
    Issue(
      id: "issue10",
      title: "No bicycle lanes",
      description:
          "Cyclists have no dedicated lanes on the new road expansion.",
      upvoteCount: 27,
      commentCount: 3,
      postedBy: "user4",
      commentIds: ['c_issue10_1', 'c_issue10_2', 'c_issue10_3'],
      imageUrl: 'https://picsum.photos/id/1105/800/1200',
    ),
  ];

  // Stored groups (collections of issues). Kept separate to minimize refactors.
  List<Group> storedGroups = [
    Group(
      id: 'group1',
      title: 'Neighborhood Safety Pack',
      description: 'A collection of safety-related reports in the north end.',
      postedBy: 'user2',
      upvoteCount: 123,
      commentCount: 4,
      issueIds: ['issue1', 'issue3', 'issue4'],
      imageUrl: 'https://picsum.photos/id/1018/800/1200',
    ),
  ];

  // Centralized list of comments. Issues reference them by id in Issue.commentIds.
  List<Comment> storedComments = [
    // sample comments for issue1
    Comment(
      id: 'c_issue1_1',
      issueId: 'issue1',
      postedBy: 'user1',
      content: 'We need better lighting on 3rd street',
    ),
    Comment(
      id: 'c_issue1_2',
      issueId: 'issue1',
      postedBy: 'user3',
      content: 'Local council contacted',
    ),
    // sample comments for issue2
    Comment(
      id: 'c_issue2_1',
      issueId: 'issue2',
      postedBy: 'user2',
      content: 'This is getting worse every week',
    ),
    Comment(
      id: 'c_issue2_2',
      issueId: 'issue2',
      postedBy: 'user4',
      content: 'I can help collect data',
    ),
    // sample comments for issue3
    Comment(
      id: 'c_issue3_1',
      issueId: 'issue3',
      postedBy: 'user1',
      content: 'Playground fixed last year?',
    ),
    Comment(
      id: 'c_issue3_2',
      issueId: 'issue3',
      postedBy: 'user2',
      content: 'Dangerous for kids',
    ),
    // sample comments for issue4
    Comment(
      id: 'c_issue4_1',
      issueId: 'issue4',
      postedBy: 'user3',
      content: 'This happens on weekends',
    ),
    // sample comments for issue5
    Comment(
      id: 'c_issue5_1',
      issueId: 'issue5',
      postedBy: 'user2',
      content: 'Water board notified',
    ),
    // sample comments for issue6
    Comment(
      id: 'c_issue6_1',
      issueId: 'issue6',
      postedBy: 'user4',
      content: 'They should clean it up',
    ),
    // sample comments for issue7
    Comment(
      id: 'c_issue7_1',
      issueId: 'issue7',
      postedBy: 'user1',
      content: 'Recycling trucks skipped our street',
    ),
    // sample comments for issue8
    Comment(
      id: 'c_issue8_1',
      issueId: 'issue8',
      postedBy: 'user3',
      content: 'My car hit one yesterday',
    ),
    // sample comments for issue9
    Comment(
      id: 'c_issue9_1',
      issueId: 'issue9',
      postedBy: 'user2',
      content: 'Bus times are unreliable',
    ),
    // sample comments for issue10
    Comment(
      id: 'c_issue10_1',
      issueId: 'issue10',
      postedBy: 'user4',
      content: 'We need bike lanes soon',
    ),
    // additional comments added to increase sample coverage
    // issue1 extras
    Comment(
      id: 'c_issue1_3',
      issueId: 'issue1',
      postedBy: 'user4',
      content: 'I avoid walking there after sunset',
    ),
    Comment(
      id: 'c_issue1_4',
      issueId: 'issue1',
      postedBy: 'user3',
      content: 'A community watch could help',
    ),
    // issue2 extra
    Comment(
      id: 'c_issue2_3',
      issueId: 'issue2',
      postedBy: 'user3',
      content: 'Report filing number: 4532',
    ),
    // issue3 extras
    Comment(
      id: 'c_issue3_3',
      issueId: 'issue3',
      postedBy: 'user2',
      content: 'City maintenance scheduled next week',
    ),
    Comment(
      id: 'c_issue3_4',
      issueId: 'issue3',
      postedBy: 'user1',
      content: 'Kids play there every afternoon',
    ),
    // issue4 extra
    Comment(
      id: 'c_issue4_2',
      issueId: 'issue4',
      postedBy: 'user2',
      content: 'License plates should be fined',
    ),
    // issue5 extras
    Comment(
      id: 'c_issue5_2',
      issueId: 'issue5',
      postedBy: 'user3',
      content: 'Last outage lasted 6 hours',
    ),
    Comment(
      id: 'c_issue5_3',
      issueId: 'issue5',
      postedBy: 'user1',
      content: 'Neighbors are collecting water in tanks',
    ),
    // issue6 extra
    Comment(
      id: 'c_issue6_2',
      issueId: 'issue6',
      postedBy: 'user3',
      content: 'Maybe a mural project?',
    ),
    // issue7 extra
    Comment(
      id: 'c_issue7_2',
      issueId: 'issue7',
      postedBy: 'user4',
      content: 'Contacted the waste management office',
    ),
    // issue8 extras
    Comment(
      id: 'c_issue8_2',
      issueId: 'issue8',
      postedBy: 'user1',
      content: 'Temporary cones placed yesterday',
    ),
    Comment(
      id: 'c_issue8_3',
      issueId: 'issue8',
      postedBy: 'user2',
      content: 'A repair crew was seen last Friday',
    ),
    // issue9 extra
    Comment(
      id: 'c_issue9_2',
      issueId: 'issue9',
      postedBy: 'user1',
      content: 'Timetable pinpoints are wrong',
    ),
    // issue10 extras
    Comment(
      id: 'c_issue10_2',
      issueId: 'issue10',
      postedBy: 'user2',
      content: 'Cyclists deserve safe lanes',
    ),
    Comment(
      id: 'c_issue10_3',
      issueId: 'issue10',
      postedBy: 'user1',
      content: 'Proposal sent to council last month',
    ),
  ];

  List<String> getCommentsIdsForIssue(String issueId) {
    return storedComments
        .where((c) => c.issueId == issueId)
        .map((x) => x.id)
        .toList();
  }

  /// Returns the comment matching [id], or a placeholder `Comment` if not found.
  Comment getCommentById(String id) {
    return storedComments.firstWhere(
      (c) => c.id == id,
      orElse: () => Comment(id: id, issueId: ''),
    );
  }

  /// Adds a comment and links it to the issue. Notifies listeners.
  void addComment(Comment comment) {
    storedComments.add(comment);
    final idx = storedIssues.indexWhere((it) => it.id == comment.issueId);
    if (idx != -1) {
      storedIssues[idx].commentIds = [
        ...storedIssues[idx].commentIds,
        comment.id,
      ];
    }
    notifyListeners();
  }

  // Track in-progress loads so we don't duplicate requests.
  final Set<String> _loading = {};

  List<FeedRef> get feedItems {
    final List<FeedRef> out = [];
    // For now, show issues first then groups. Server will replace this later.
    out.addAll(storedIssues.map((i) => FeedRef(i.id, false)));
    out.addAll(storedGroups.map((g) => FeedRef(g.id, true)));
    return out;
  }

  Issue getIssueById(String id) =>
      storedIssues.firstWhere((it) => it.id == id, orElse: () => Issue(id: id));

  Group getGroupById(String id) =>
      storedGroups.firstWhere((it) => it.id == id, orElse: () => Group(id: id));

  /// Returns the user matching [id], or a placeholder `User` if not found.
  User getUserById(String id) {
    final user = storedUsers.firstWhere(
      (u) => u.id == id,
      orElse: () => User(id: id, name: 'Unknown'),
    );

    // Trigger background load of the user's image if we have a URL and it's not loaded yet.
    if (!user.loaded &&
        user.imageUrl != null &&
        !_loading.contains('user:$id')) {
      // Fire-and-forget; loadUserData manages _loading set to avoid duplicates.
      loadUserData(id);
    }

    return user;
  }

  /// Loads a user's profile image (if configured). Uses a prefixed loading key to avoid collisions.
  Future<void> loadUserData(String id) async {
    final user = storedUsers.firstWhere(
      (it) => it.id == id,
      orElse: () => User(id: id),
    );

    if (user.loaded && user.imageData != null && user.imageData!.isNotEmpty)
      return;
    if (_loading.contains('user:$id')) return;
    if (user.imageUrl == null) return;

    _loading.add('user:$id');
    try {
      final uri = Uri.parse(user.imageUrl!);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      if (bytes.isNotEmpty) {
        user.imageData = Uint8List.fromList(bytes);
        user.loaded = true;
      } else {
        user.imageData = null;
        user.loaded = false;
      }
      notifyListeners();
    } catch (e) {
      // ignore errors for now
    } finally {
      _loading.remove('user:$id');
    }
  }

  /// Returns the role matching [id], or a placeholder `Role` if not found.
  Role getRoleById(String id) {
    return storedRoles.firstWhere(
      (r) => r.id == id,
      orElse: () => Role(id: id, title: 'Unknown'),
    );
  }

  Future<void> reloadUserData(String id) async {
    final user = storedUsers.firstWhere(
      (it) => it.id == id,
      orElse: () => User(id: id),
    );
    user.imageData = null;
    user.loaded = false;
    notifyListeners();
    await loadUserData(id);
  }

  Future<void> loadIssueData(String id) async {
    final issue = storedIssues.firstWhere(
      (it) => it.id == id,
      orElse: () => Issue(id: id),
    );

    // If already successfully loaded (non-empty bytes), skip.
    if (issue.loaded && issue.imageData != null && issue.imageData!.isNotEmpty)
      return;
    if (_loading.contains(id)) return;
    if (issue.imageUrl == null) return;

    _loading.add(id);
    try {
      final uri = Uri.parse(issue.imageUrl!);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      if (bytes.isNotEmpty) {
        issue.imageData = Uint8List.fromList(bytes);
        issue.loaded = true;
      } else {
        // treat empty response as failed load
        issue.imageData = null;
        issue.loaded = false;
      }
      notifyListeners();
    } catch (e) {
      // ignore errors for now; keep loaded=false
    } finally {
      _loading.remove(id);
    }
  }

  /// Loads the group's image data (only primary display image).
  Future<void> loadGroupData(String id) async {
    final group = storedGroups.firstWhere(
      (it) => it.id == id,
      orElse: () => Group(id: id),
    );

    if (group.loaded && group.imageData != null && group.imageData!.isNotEmpty)
      return;
    if (_loading.contains('group:$id')) return;
    if (group.imageUrl == null) return;

    _loading.add('group:$id');
    try {
      final uri = Uri.parse(group.imageUrl!);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      if (bytes.isNotEmpty) {
        group.imageData = Uint8List.fromList(bytes);
        group.loaded = true;
      } else {
        group.imageData = null;
        group.loaded = false;
      }
      notifyListeners();
    } catch (e) {
      // ignore for now
    } finally {
      _loading.remove('group:$id');
    }
  }

  Future<void> reloadGroupData(String id) async {
    final group = storedGroups.firstWhere(
      (it) => it.id == id,
      orElse: () => Group(id: id),
    );
    group.imageData = null;
    group.loaded = false;
    notifyListeners();
    await loadGroupData(id);
  }

  /// Returns whether the loader is currently fetching the issue data.
  /// Returns whether the loader is currently fetching the issue or group data.
  bool isLoading(String id, {bool isGroup = false, bool isUser = false}) {
    if (isGroup) return _loading.contains('group:$id');
    if (isUser) return _loading.contains('user:$id');
    return _loading.contains(id);
  }

  /// Force reloading the issue image data (clears previous bytes and attempts load).
  Future<void> reloadIssueData(String id) async {
    final issue = storedIssues.firstWhere(
      (it) => it.id == id,
      orElse: () => Issue(id: id),
    );
    issue.imageData = null;
    issue.loaded = false;
    notifyListeners();
    await loadIssueData(id);
  }
}
