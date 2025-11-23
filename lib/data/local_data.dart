import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:social_issues_tracker/data/models/issue.dart';
import 'package:social_issues_tracker/data/models/group.dart';
import 'package:social_issues_tracker/data/models/comment.dart';
import 'package:social_issues_tracker/data/models/user.dart' as models;
import 'package:social_issues_tracker/data/models/role.dart';
import 'package:social_issues_tracker/data/models/file_attachment.dart';
import 'package:social_issues_tracker/data/models/group_join_request.dart';
import 'package:http/http.dart' as http;
import 'package:social_issues_tracker/utils/auth_helper.dart';
import 'package:social_issues_tracker/constants.dart';

// Lightweight descriptor for feed entries used by the homepage reel.
class FeedRef {
  final String id;
  final bool isGroup;
  FeedRef(this.id, this.isGroup);
}

class LocalData with ChangeNotifier {
  // Simulated logged-in user; used as `postedBy` for new issues.
  String loggedInUserId =
      'user1'; // will be replaced by Supabase auth user id when logged in

  void setLoggedInUser(String userId) {
    loggedInUserId = userId;
    // Optionally ensure a placeholder User exists for UI continuity
    final exists = storedUsers.any((u) => u.id == userId);
    if (!exists) {
      storedUsers.add(
        models.User(id: userId, name: 'User'),
      ); // minimal placeholder
    }
    notifyListeners();
  }

  List<models.User> storedUsers = [
    models.User(
      id: "user1",
      name: "Sarim Ahmed",
      role: "1",
      imageUrl: 'https://api.dicebear.com/9.x/pixel-art/png?seed=Sarim%20Ahmed',
    ),
    models.User(
      id: "user2",
      name: "Aisha Khan",
      role: "2",
      imageUrl: 'https://api.dicebear.com/9.x/pixel-art/png?seed=Aisha%20Khan',
    ),
    models.User(
      id: "user3",
      name: "Daniel Park",
      role: "2",
      imageUrl: 'https://api.dicebear.com/9.x/pixel-art/png?seed=Daniel%20Park',
    ),
    models.User(
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
      fileIds: ['f_issue1_report', 'f_issue1_photo1'],
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
      fileIds: ['f_issue2_bins', 'f_issue2_stats'],
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
      fileIds: ['f_issue3_equipment_photo'],
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
      fileIds: ['f_issue4_parking_map'],
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
      fileIds: ['f_issue5_outage_log'],
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
      fileIds: ['f_issue6_graffiti_photo'],
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
      fileIds: ['f_issue7_recycling_schedule'],
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
      fileIds: ['f_issue8_pothole_photo'],
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
      fileIds: ['f_issue9_timetable_scan'],
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
      fileIds: ['f_issue10_road_plan'],
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
      fileIds: ['f_group1_summary', 'f_group1_map'],
    ),
  ];

  // Stored join requests between issues and groups.
  List<GroupJoinRequest> storedGroupJoinRequests = [];

  int _groupJoinRequestCounter = 1;

  String nextGroupJoinRequestId() => 'gjr${_groupJoinRequestCounter++}';

  // Stored file attachments referenced by issues/groups via their fileIds.
  List<FileAttachment> storedFiles = [
    FileAttachment(
      id: 'f_issue1_report',
      name: 'lighting_survey',
      extension: 'pdf',
      uploadLink: 'https://example.com/files/lighting_survey.pdf',
    ),
    FileAttachment(
      id: 'f_issue1_photo1',
      name: 'street_lamp_before',
      extension: 'jpg',
      uploadLink: 'https://picsum.photos/id/111/600/400',
    ),
    FileAttachment(
      id: 'f_issue2_bins',
      name: 'overflow_bins_weekend',
      extension: 'jpg',
      uploadLink: 'https://picsum.photos/id/112/600/400',
    ),
    FileAttachment(
      id: 'f_issue2_stats',
      name: 'waste_collection_stats',
      extension: 'xlsx',
      uploadLink: 'https://example.com/files/waste_stats.xlsx',
    ),
    FileAttachment(
      id: 'f_issue3_equipment_photo',
      name: 'broken_swing',
      extension: 'jpg',
      uploadLink: 'https://picsum.photos/id/113/600/400',
    ),
    FileAttachment(
      id: 'f_issue4_parking_map',
      name: 'sidewalk_parking_locations',
      extension: 'png',
      uploadLink: 'https://picsum.photos/id/114/600/400',
    ),
    FileAttachment(
      id: 'f_issue5_outage_log',
      name: 'water_outage_log',
      extension: 'csv',
      uploadLink: 'https://example.com/files/outage_log.csv',
    ),
    FileAttachment(
      id: 'f_issue6_graffiti_photo',
      name: 'graffiti_library_wall',
      extension: 'jpg',
      uploadLink: 'https://picsum.photos/id/115/600/400',
    ),
    FileAttachment(
      id: 'f_issue7_recycling_schedule',
      name: 'recycling_schedule_official',
      extension: 'pdf',
      uploadLink: 'https://example.com/files/recycling_schedule.pdf',
    ),
    FileAttachment(
      id: 'f_issue8_pothole_photo',
      name: 'main_st_pothole',
      extension: 'jpg',
      uploadLink: 'https://picsum.photos/id/116/600/400',
    ),
    FileAttachment(
      id: 'f_issue9_timetable_scan',
      name: 'bus_timetable_scan',
      extension: 'pdf',
      uploadLink: 'https://example.com/files/bus_timetable_scan.pdf',
    ),
    FileAttachment(
      id: 'f_issue10_road_plan',
      name: 'road_expansion_plan',
      extension: 'pdf',
      uploadLink: 'https://example.com/files/road_expansion_plan.pdf',
    ),
    FileAttachment(
      id: 'f_group1_summary',
      name: 'safety_pack_summary',
      extension: 'pdf',
      uploadLink: 'https://example.com/files/safety_pack_summary.pdf',
    ),
    FileAttachment(
      id: 'f_group1_map',
      name: 'north_end_incident_map',
      extension: 'png',
      uploadLink: 'https://picsum.photos/id/117/600/400',
    ),
  ];

  GroupJoinRequest addGroupJoinRequest({
    required String issueId,
    required String groupId,
    required bool requestedByGroup,
  }) {
    // Prevent duplicate pending requests in same direction.
    final existingPending = storedGroupJoinRequests.any(
      (r) =>
          r.issueId == issueId &&
          r.groupId == groupId &&
          r.requestedByGroup == requestedByGroup &&
          r.status == GroupJoinRequestStatus.pending,
    );
    if (existingPending) {
      return storedGroupJoinRequests.firstWhere(
        (r) =>
            r.issueId == issueId &&
            r.groupId == groupId &&
            r.requestedByGroup == requestedByGroup &&
            r.status == GroupJoinRequestStatus.pending,
      );
    }

    // If already linked, don't create a new request.
    final group = storedGroups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw Exception('Group not found'),
    );
    if (group.issueIds.contains(issueId)) {
      throw Exception('Issue already belongs to this group');
    }

    final request = GroupJoinRequest(
      id: nextGroupJoinRequestId(),
      issueId: issueId,
      groupId: groupId,
      requestedByGroup: requestedByGroup,
    );
    storedGroupJoinRequests = [...storedGroupJoinRequests, request];
    notifyListeners();
    return request;
  }

  void updateGroupJoinRequestStatus(
    String requestId,
    GroupJoinRequestStatus newStatus,
  ) {
    final index = storedGroupJoinRequests.indexWhere(
      (element) => element.id == requestId,
    );
    if (index == -1) return;
    final request = storedGroupJoinRequests[index];
    if (request.status == newStatus) return;
    if (request.status != GroupJoinRequestStatus.pending) return;

    request.status = newStatus;
    if (newStatus == GroupJoinRequestStatus.accepted ||
        newStatus == GroupJoinRequestStatus.declined ||
        newStatus == GroupJoinRequestStatus.cancelled) {
      request.handledAt = DateTime.now();
    }

    if (newStatus == GroupJoinRequestStatus.accepted) {
      addIssueToGroup(request.issueId, request.groupId);
    }

    notifyListeners();
  }

  bool canCurrentUserRequestIssueToJoinGroup(String issueId, String groupId) {
    if (!isIssueOwner(issueId, loggedInUserId)) return false;

    final groupIndex = storedGroups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return false;
    final group = storedGroups[groupIndex];
    if (group.issueIds.contains(issueId)) return false;

    final hasPending = storedGroupJoinRequests.any(
      (r) =>
          r.issueId == issueId &&
          r.groupId == groupId &&
          r.requestedByGroup == false &&
          r.status == GroupJoinRequestStatus.pending,
    );
    return !hasPending;
  }

  bool canCurrentUserRequestGroupToIncludeIssue(
    String groupId,
    String issueId,
  ) {
    if (!isGroupOwner(groupId, loggedInUserId)) return false;

    final groupIndex = storedGroups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return false;
    final group = storedGroups[groupIndex];
    if (group.issueIds.contains(issueId)) return false;

    final hasPending = storedGroupJoinRequests.any(
      (r) =>
          r.issueId == issueId &&
          r.groupId == groupId &&
          r.requestedByGroup == true &&
          r.status == GroupJoinRequestStatus.pending,
    );
    return !hasPending;
  }

  bool canCurrentUserActOnRequest(GroupJoinRequest request) {
    if (request.status != GroupJoinRequestStatus.pending) return false;
    if (request.requestedByGroup) {
      // Group requested to include an external issue; issue owner is target.
      return isIssueOwner(request.issueId, loggedInUserId);
    } else {
      // Issue requested to join an external group; group owner is target.
      return isGroupOwner(request.groupId, loggedInUserId);
    }
  }

  bool canCurrentUserCancelRequest(GroupJoinRequest request) {
    if (request.status != GroupJoinRequestStatus.pending) return false;
    if (request.requestedByGroup) {
      return isGroupOwner(request.groupId, loggedInUserId);
    } else {
      return isIssueOwner(request.issueId, loggedInUserId);
    }
  }

  List<GroupJoinRequest> getRequestsForIssue(String issueId) {
    return storedGroupJoinRequests.where((r) => r.issueId == issueId).toList();
  }

  List<GroupJoinRequest> getRequestsForGroup(String groupId) {
    return storedGroupJoinRequests.where((r) => r.groupId == groupId).toList();
  }

  List<GroupJoinRequest> get incomingRequestsForCurrentUser {
    return storedGroupJoinRequests.where((r) {
      if (r.requestedByGroup) {
        // Incoming for issue owner.
        return isIssueOwner(r.issueId, loggedInUserId);
      } else {
        // Incoming for group owner.
        return isGroupOwner(r.groupId, loggedInUserId);
      }
    }).toList();
  }

  List<GroupJoinRequest> get outgoingRequestsForCurrentUser {
    return storedGroupJoinRequests.where((r) {
      if (r.requestedByGroup) {
        // Outgoing from group owner.
        return isGroupOwner(r.groupId, loggedInUserId);
      } else {
        // Outgoing from issue owner.
        return isIssueOwner(r.issueId, loggedInUserId);
      }
    }).toList();
  }

  void addIssueToGroup(String issueId, String groupId) {
    try {
      final groupIndex = storedGroups.indexWhere((g) => g.id == groupId);
      if (groupIndex == -1) return;
      final group = storedGroups[groupIndex];
      if (group.issueIds.contains(issueId)) return;
      group.issueIds = [...group.issueIds, issueId];
      notifyListeners();
    } catch (_) {}
  }

  bool isIssueOwner(String issueId, String userId) {
    try {
      final issue = storedIssues.firstWhere((i) => i.id == issueId);
      return issue.postedBy == userId;
    } catch (_) {
      return false;
    }
  }

  bool isGroupOwner(String groupId, String userId) {
    try {
      final group = storedGroups.firstWhere((g) => g.id == groupId);
      return group.postedBy == userId;
    } catch (_) {
      return false;
    }
  }

  FileAttachment getFileById(String id) => storedFiles.firstWhere(
    (f) => f.id == id,
    orElse: () => FileAttachment(
      id: id,
      name: 'unknown',
      extension: 'dat',
      uploadLink: '',
    ),
  );

  /// Ensures a FileAttachment is present in [storedFiles], returning the
  /// existing one if an item with the same id already exists.
  FileAttachment ensureFileStored(FileAttachment file) {
    final index = storedFiles.indexWhere((f) => f.id == file.id);
    if (index != -1) return storedFiles[index];
    storedFiles.add(file);
    return file;
  }

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

  /// Generates a new incremental group id (e.g. `group2`).
  String nextGroupId() {
    int maxId = 0;
    for (final it in storedGroups) {
      if (it.id.startsWith('group')) {
        final tail = int.tryParse(it.id.replaceFirst('group', '')) ?? 0;
        if (tail > maxId) maxId = tail;
      }
    }
    return 'group${maxId + 1}';
  }

  /// Adds a new group to the in-memory list and notifies listeners.
  void addGroup(Group group) {
    storedGroups.add(group);
    notifyListeners();
  }

  /// Generates a new incremental issue id (e.g. `issue11`).
  String nextIssueId() {
    int maxId = 0;
    for (final it in storedIssues) {
      if (it.id.startsWith('issue')) {
        final tail = int.tryParse(it.id.replaceFirst('issue', '')) ?? 0;
        if (tail > maxId) maxId = tail;
      }
    }
    return 'issue${maxId + 1}';
  }

  /// Adds a new issue to the in-memory list and notifies listeners.
  /// Now integrated with backend API
  Future<String?> addIssue({
    required String title,
    required String description,
    Uint8List? displayPictureBytes,
    String? displayPictureExtension,
    List<FileAttachment>? attachments,
  }) async {
    try {
      final token = await AuthHelper.getToken();

      if (token == null) {
        debugPrint('[addIssue] No auth token');
        return null;
      }

      // TODO: Update this to use your backend endpoint when you implement it
      final url = '$apiBaseUrl/issues';
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add title and description
      request.fields['title'] = title;
      request.fields['description'] = description;

      // Add display picture if provided
      if (displayPictureBytes != null && displayPictureExtension != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'display_picture',
            displayPictureBytes,
            filename: 'display_picture.$displayPictureExtension',
          ),
        );
      }

      // Add attachments if provided
      if (attachments != null && attachments.isNotEmpty) {
        for (final attachment in attachments) {
          if (attachment.fileData != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'attachments',
                attachment.fileData!,
                filename: '${attachment.name}.${attachment.extension}',
              ),
            );
          }
        }
      }

      debugPrint('[addIssue] Sending request to edge function...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[addIssue] Response status: ${response.statusCode}');
      debugPrint('[addIssue] Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final issueId = data['issue_id'] as String;
        final displayPictureUrl = data['display_picture_url'] as String?;

        // Create issue object and add to local storage
        final issue = Issue(
          id: issueId,
          title: title,
          description: description,
          postedBy: loggedInUserId,
          upvoteCount: 0,
          commentCount: 0,
          displayPictureUrl: displayPictureUrl,
          imageUrl: displayPictureUrl != null
              ? getFullImageUrl(displayPictureUrl)
              : null,
          postedAt: DateTime.now(),
        );

        // Load the display picture if available
        if (displayPictureBytes != null) {
          issue.imageData = displayPictureBytes;
          issue.loaded = true;
        }

        storedIssues.add(issue);
        notifyListeners();

        debugPrint('[addIssue] Issue created successfully: $issueId');
        return issueId;
      } else {
        final error = json.decode(response.body);
        debugPrint('[addIssue] Error creating issue: ${error['error']}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('[addIssue] Exception: $e');
      debugPrint('[addIssue] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get issue by ID, now fetches from database first, falls back to local
  Future<Issue?> fetchIssueById(String id) async {
    try {
      final token = await AuthHelper.getToken();

      if (token == null) {
        debugPrint('[fetchIssueById] No auth token');
        // Fallback to local storage
        final localIssue = storedIssues.firstWhere(
          (it) => it.id == id,
          orElse: () => Issue(id: id),
        );
        return localIssue.title != null ? localIssue : null;
      }

      // TODO: Update this to use your backend endpoint when you implement it
      final url = '$apiBaseUrl/issues/$id';
      debugPrint('[fetchIssueById] Fetching issue from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[fetchIssueById] Response status: ${response.statusCode}');
      debugPrint('[fetchIssueById] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse the issue data
        final displayPictureUrl = data['display_picture_url'] as String?;
        final issue = Issue(
          id: data['issue_id'] as String,
          title: data['title'] as String?,
          description: data['description'] as String?,
          postedBy: data['user_id'] as String?,
          upvoteCount: data['upvote_count'] as int?,
          groupId: data['group_id'] as String?,
          displayPictureUrl: displayPictureUrl,
          imageUrl: displayPictureUrl != null
              ? getFullImageUrl(displayPictureUrl)
              : null,
          postedAt: data['posted_at'] != null
              ? DateTime.parse(data['posted_at'] as String)
              : null,
          attachments: data['attachments'] != null
              ? List<Map<String, dynamic>>.from(data['attachments'] as List)
              : null,
        );

        // Update or add to local storage
        final existingIndex = storedIssues.indexWhere((it) => it.id == id);
        if (existingIndex != -1) {
          storedIssues[existingIndex] = issue;
        } else {
          storedIssues.add(issue);
        }

        notifyListeners();

        // Trigger image load if we have a URL
        if (issue.imageUrl != null && !issue.loaded) {
          loadIssueData(id);
        }

        debugPrint(
          '[fetchIssueById] Issue fetched successfully: ${issue.title}',
        );
        return issue;
      } else if (response.statusCode == 404) {
        debugPrint(
          '[fetchIssueById] Issue not found in database, checking local storage',
        );
        // Fallback to dummy/local data
        final localIssue = storedIssues.firstWhere(
          (it) => it.id == id,
          orElse: () => Issue(id: id),
        );
        return localIssue.title != null ? localIssue : null;
      } else {
        final error = json.decode(response.body);
        debugPrint('[fetchIssueById] Error fetching issue: ${error['error']}');
        // Fallback to local storage
        final localIssue = storedIssues.firstWhere(
          (it) => it.id == id,
          orElse: () => Issue(id: id),
        );
        return localIssue.title != null ? localIssue : null;
      }
    } catch (e, stackTrace) {
      debugPrint('[fetchIssueById] Exception: $e');
      debugPrint('[fetchIssueById] Stack trace: $stackTrace');
      // Fallback to local storage
      final localIssue = storedIssues.firstWhere(
        (it) => it.id == id,
        orElse: () => Issue(id: id),
      );
      return localIssue.title != null ? localIssue : null;
    }
  }

  Issue getIssueById(String id) =>
      storedIssues.firstWhere((it) => it.id == id, orElse: () => Issue(id: id));

  Group getGroupById(String id) =>
      storedGroups.firstWhere((it) => it.id == id, orElse: () => Group(id: id));

  /// Returns the user matching [id], or a placeholder `User` if not found.
  models.User getUserById(String id) {
    final user = storedUsers.firstWhere(
      (u) => u.id == id,
      orElse: () => models.User(id: id, name: 'Unknown'),
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
      orElse: () => models.User(id: id),
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
      orElse: () => models.User(id: id),
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
