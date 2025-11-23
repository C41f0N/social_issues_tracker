import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path/path.dart' as path;

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

  // Feed issue IDs in order of recency
  List<String> feedIssueIds = [];

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

  List<models.User> storedUsers = [];

  // Stored roles (small lookup table)
  List<Role> storedRoles = [
    Role(id: '1', title: 'Citizen'),
    Role(id: '2', title: 'Lawyer'),
    Role(id: '3', title: 'Council Member'),
  ];

  List<Issue> storedIssues = [];

  // Stored groups (collections of issues). Kept separate to minimize refactors.
  List<Group> storedGroups = [];

  // Stored join requests between issues and groups.
  List<GroupJoinRequest> storedGroupJoinRequests = [];

  int _groupJoinRequestCounter = 1;

  String nextGroupJoinRequestId() => 'gjr${_groupJoinRequestCounter++}';

  // Stored file attachments referenced by issues/groups via their fileIds.
  List<FileAttachment> storedFiles = [];

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
    if (group.issueIds?.contains(issueId) ?? false) {
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
    if (group.issueIds?.contains(issueId) ?? false) return false;

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
    if (group.issueIds?.contains(issueId) ?? false) return false;

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
      if (group.issueIds?.contains(issueId) ?? false) return;
      group.issueIds = [...?group.issueIds, issueId];
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
  List<Comment> storedComments = [];

  /// Fetch users who upvoted an issue
  Future<List<models.User>> fetchUpvotesForIssue(String issueId) async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        debugPrint('[fetchUpvotesForIssue] No auth token');
        return [];
      }

      final url = '$apiBaseUrl/issues/$issueId/upvotes';
      debugPrint('[fetchUpvotesForIssue] Fetching upvotes from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        '[fetchUpvotesForIssue] Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final upvotesList = data['upvotes'] as List;

        final List<models.User> upvoters = [];
        for (final upvoteData in upvotesList) {
          final userId = upvoteData['user_id'] as String;
          final username = upvoteData['username'] as String?;
          final fullName = upvoteData['full_name'] as String?;

          // Create or update user
          final existingUserIndex = storedUsers.indexWhere(
            (u) => u.id == userId,
          );
          final user = models.User(
            id: userId,
            name: fullName ?? username ?? 'Unknown',
            imageUrl:
                'https://api.dicebear.com/9.x/pixel-art/png?seed=${Uri.encodeComponent(username ?? userId)}',
          );

          if (existingUserIndex == -1) {
            storedUsers.add(user);
          } else {
            storedUsers[existingUserIndex] = user;
          }

          upvoters.add(user);
        }

        debugPrint('[fetchUpvotesForIssue] Loaded ${upvoters.length} upvoters');
        return upvoters;
      } else {
        debugPrint('[fetchUpvotesForIssue] Error: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('[fetchUpvotesForIssue] Exception: $e');
      debugPrint('[fetchUpvotesForIssue] Stack trace: $stackTrace');
      return [];
    }
  }

  List<String> getCommentsIdsForIssue(String issueId) {
    // Trigger background fetch if not already loaded
    if (!_loading.contains('comments:$issueId')) {
      fetchCommentsForIssue(issueId);
    }

    return storedComments
        .where((c) => c.issueId == issueId)
        .map((x) => x.id)
        .toList();
  }

  /// Fetch comments for an issue from backend
  Future<void> fetchCommentsForIssue(String issueId) async {
    if (_loading.contains('comments:$issueId')) return;

    _loading.add('comments:$issueId');
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        debugPrint('[fetchCommentsForIssue] No auth token');
        return;
      }

      final url = '$apiBaseUrl/issues/$issueId/comments';
      debugPrint('[fetchCommentsForIssue] Fetching comments from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        '[fetchCommentsForIssue] Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final commentsList = data['comments'] as List;

        // Remove existing comments for this issue
        storedComments.removeWhere((c) => c.issueId == issueId);

        final List<String> commentIds = [];
        for (final commentData in commentsList) {
          final commentId = commentData['comment_id'] as String;
          final userId = commentData['user_id'] as String;
          final username = commentData['username'] as String?;
          final fullName = commentData['full_name'] as String?;

          // Create or update user
          final existingUserIndex = storedUsers.indexWhere(
            (u) => u.id == userId,
          );
          final user = models.User(
            id: userId,
            name: fullName ?? username ?? 'Unknown',
            imageUrl:
                'https://api.dicebear.com/9.x/pixel-art/png?seed=${Uri.encodeComponent(username ?? userId)}',
          );

          if (existingUserIndex == -1) {
            storedUsers.add(user);
          } else {
            storedUsers[existingUserIndex] = user;
          }

          // Create comment
          final comment = Comment(
            id: commentId,
            issueId: issueId,
            postedBy: userId,
            content: commentData['content'] as String,
            postedAt: DateTime.parse(commentData['posted_at'] as String),
          );

          storedComments.add(comment);
          commentIds.add(commentId);
        }

        // Update issue's comment IDs
        final issueIndex = storedIssues.indexWhere((it) => it.id == issueId);
        if (issueIndex != -1) {
          storedIssues[issueIndex].commentIds = commentIds;
        }

        notifyListeners();
        debugPrint(
          '[fetchCommentsForIssue] Loaded ${commentIds.length} comments',
        );
      } else {
        debugPrint('[fetchCommentsForIssue] Error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('[fetchCommentsForIssue] Exception: $e');
      debugPrint('[fetchCommentsForIssue] Stack trace: $stackTrace');
    } finally {
      _loading.remove('comments:$issueId');
    }
  }

  /// Returns the comment matching [id], or a placeholder `Comment` if not found.
  Comment getCommentById(String id) {
    return storedComments.firstWhere(
      (c) => c.id == id,
      orElse: () => Comment(id: id, issueId: ''),
    );
  }

  /// Adds a comment and links it to the issue. Posts to backend.
  Future<void> addComment(Comment comment) async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        debugPrint('[addComment] No auth token');
        return;
      }

      final url = '$apiBaseUrl/issues/${comment.issueId}/comments';
      debugPrint('[addComment] Posting comment to: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': comment.content}),
      );

      debugPrint('[addComment] Response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final commentId = data['comment_id'] as String;
        final userId = data['user_id'] as String;
        final username = data['username'] as String?;
        final fullName = data['full_name'] as String?;

        // Create or update user
        final existingUserIndex = storedUsers.indexWhere((u) => u.id == userId);
        final user = models.User(
          id: userId,
          name: fullName ?? username ?? 'Unknown',
          imageUrl:
              'https://api.dicebear.com/9.x/pixel-art/png?seed=${Uri.encodeComponent(username ?? userId)}',
        );

        if (existingUserIndex == -1) {
          storedUsers.add(user);
        } else {
          storedUsers[existingUserIndex] = user;
        }

        // Create comment with backend data
        final newComment = Comment(
          id: commentId,
          issueId: comment.issueId,
          postedBy: userId,
          content: data['content'] as String,
          postedAt: DateTime.parse(data['posted_at'] as String),
        );

        storedComments.add(newComment);

        // Update issue's comment IDs and count
        final idx = storedIssues.indexWhere((it) => it.id == comment.issueId);
        if (idx != -1) {
          storedIssues[idx].commentIds = [
            ...storedIssues[idx].commentIds,
            commentId,
          ];
          // Increment comment count
          storedIssues[idx].commentCount =
              (storedIssues[idx].commentCount ?? 0) + 1;
        }

        notifyListeners();
        debugPrint('[addComment] Comment added successfully');
      } else {
        debugPrint('[addComment] Error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('[addComment] Exception: $e');
      debugPrint('[addComment] Stack trace: $stackTrace');
    }
  }

  /// Toggle upvote for an issue
  Future<bool> toggleIssueUpvote(String issueId) async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        debugPrint('[toggleIssueUpvote] No auth token');
        return false;
      }

      final url = '$apiBaseUrl/issues/$issueId/upvote';
      debugPrint('[toggleIssueUpvote] Toggling upvote at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[toggleIssueUpvote] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final upvoted = data['upvoted'] as bool;
        final upvoteCount = data['upvote_count'] as int;

        // Update issue's upvote count
        final issueIndex = storedIssues.indexWhere((it) => it.id == issueId);
        if (issueIndex != -1) {
          storedIssues[issueIndex].upvoteCount = upvoteCount;
        }

        // Update cache
        _upvoteCache[issueId] = upvoted;

        notifyListeners();
        debugPrint(
          '[toggleIssueUpvote] Upvoted: $upvoted, Count: $upvoteCount',
        );
        return upvoted;
      } else {
        debugPrint('[toggleIssueUpvote] Error: ${response.statusCode}');
        return _upvoteCache[issueId] ?? false;
      }
    } catch (e, stackTrace) {
      debugPrint('[toggleIssueUpvote] Exception: $e');
      debugPrint('[toggleIssueUpvote] Stack trace: $stackTrace');
      return _upvoteCache[issueId] ?? false;
    }
  }

  /// Check if current user has upvoted an issue
  Future<bool> checkIfUpvoted(String issueId) async {
    // Return cached value if available
    if (_upvoteCache.containsKey(issueId)) {
      return _upvoteCache[issueId]!;
    }

    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        return false;
      }

      // Fetch upvotes and check if current user is in the list
      final upvoters = await fetchUpvotesForIssue(issueId);
      final isUpvoted = upvoters.any((user) => user.id == loggedInUserId);

      // Cache the result
      _upvoteCache[issueId] = isUpvoted;

      return isUpvoted;
    } catch (e) {
      debugPrint('[checkIfUpvoted] Exception: $e');
      return false;
    }
  }

  // Track in-progress loads so we don't duplicate requests.
  final Set<String> _loading = {};

  // Cache upvote status for issues
  final Map<String, bool> _upvoteCache = {};

  // Store combined feed order from backend
  List<FeedRef> _feedItems = [];

  List<FeedRef> get feedItems {
    // If we have feed from backend, use that order
    if (_feedItems.isNotEmpty) {
      return _feedItems;
    }

    // Fallback to showing all items if feed not loaded yet
    final List<FeedRef> out = [];
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

  /// Fetch recent feed from backend and populate storedIssues and storedGroups
  Future<void> fetchRecentFeed() async {
    try {
      final token = await AuthHelper.getToken();

      if (token == null) {
        debugPrint('[fetchRecentFeed] No auth token');
        return;
      }

      final url = '$apiBaseUrl/issues/feed';
      debugPrint('[fetchRecentFeed] Fetching feed from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[fetchRecentFeed] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final itemsJson = data['items'] as List;

        // Clear existing feed
        feedIssueIds.clear();
        _feedItems.clear();

        // Parse and store items
        for (final itemData in itemsJson) {
          final itemType = itemData['item_type'] as String;
          final userId = itemData['user_id'] as String;
          final username = itemData['username'] as String?;
          final fullName = itemData['full_name'] as String?;
          final displayPictureUrl = itemData['display_picture_url'] as String?;

          // Create or update user in storedUsers
          final existingUserIndex = storedUsers.indexWhere(
            (u) => u.id == userId,
          );
          final user = models.User(
            id: userId,
            name: fullName ?? username ?? 'Unknown',
            imageUrl:
                'https://api.dicebear.com/9.x/pixel-art/png?seed=${Uri.encodeComponent(username ?? userId)}',
          );

          if (existingUserIndex == -1) {
            storedUsers.add(user);
          } else {
            storedUsers[existingUserIndex] = user;
          }

          if (itemType == 'issue') {
            final issue = Issue(
              id: itemData['id'] as String,
              title: itemData['title'] as String?,
              description: itemData['description'] as String?,
              postedBy: userId,
              upvoteCount: itemData['upvote_count'] as int?,
              commentCount: itemData['comment_count'] as int?,
              displayPictureUrl: displayPictureUrl,
              imageUrl: displayPictureUrl != null
                  ? getFullImageUrl(displayPictureUrl)
                  : null,
              postedAt: itemData['posted_at'] != null
                  ? DateTime.parse(itemData['posted_at'] as String)
                  : null,
            );
            issue.fullyLoaded = false; // Mark as not fully loaded

            // Check if issue already exists
            final existingIssueIndex = storedIssues.indexWhere(
              (i) => i.id == issue.id,
            );
            if (existingIssueIndex == -1) {
              storedIssues.add(issue);
            } else {
              storedIssues[existingIssueIndex] = issue;
            }

            _feedItems.add(FeedRef(issue.id, false));
          } else if (itemType == 'group') {
            final group = Group(
              id: itemData['id'] as String,
              title: itemData['title'] as String?,
              description: itemData['description'] as String?,
              postedBy: userId,
              upvoteCount: itemData['upvote_count'] as int?,
              commentCount: itemData['comment_count'] as int?,
              displayPictureUrl: displayPictureUrl,
              imageUrl: displayPictureUrl != null
                  ? getFullImageUrl(displayPictureUrl)
                  : null,
            );
            group.loaded = false; // Mark as not fully loaded

            // Check if group already exists
            final existingGroupIndex = storedGroups.indexWhere(
              (g) => g.id == group.id,
            );
            if (existingGroupIndex == -1) {
              storedGroups.add(group);
            } else {
              storedGroups[existingGroupIndex] = group;
            }

            _feedItems.add(FeedRef(group.id, true));
          }
        }

        notifyListeners();
        debugPrint(
          '[fetchRecentFeed] Loaded ${_feedItems.length} items into feed (${_feedItems.where((f) => !f.isGroup).length} issues, ${_feedItems.where((f) => f.isGroup).length} groups)',
        );
      } else {
        debugPrint('[fetchRecentFeed] Error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('[fetchRecentFeed] Exception: $e');
      debugPrint('[fetchRecentFeed] Stack trace: $stackTrace');
    }
  }

  /// Creates a new group via backend API
  Future<String?> createGroup({
    required String name,
    required String description,
    Uint8List? displayPictureBytes,
    String? displayPictureExtension,
  }) async {
    try {
      final token = await AuthHelper.getToken();

      if (token == null) {
        debugPrint('[createGroup] No auth token');
        return null;
      }

      final url = '$apiBaseUrl/groups';
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add name and description
      request.fields['name'] = name;
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

      debugPrint('[createGroup] Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[createGroup] Response status: ${response.statusCode}');
      debugPrint('[createGroup] Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final groupId = data['group_id'] as String;
        final displayPictureUrl = data['display_picture_url'] as String?;

        // Create group object and add to local storage
        final group = Group(
          id: groupId,
          title: name,
          description: description,
          postedBy: loggedInUserId,
          upvoteCount: 0,
          commentCount: 0,
          displayPictureUrl: displayPictureUrl,
          imageUrl: displayPictureUrl != null
              ? getFullImageUrl(displayPictureUrl)
              : null,
        );

        // Load the display picture if available
        if (displayPictureBytes != null) {
          group.imageData = displayPictureBytes;
          group.loaded = true;
        }

        storedGroups.add(group);
        notifyListeners();

        debugPrint('[createGroup] Group created successfully: $groupId');
        return groupId;
      } else {
        final error = json.decode(response.body);
        debugPrint('[createGroup] Error creating group: ${error['error']}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('[createGroup] Exception: $e');
      debugPrint('[createGroup] Stack trace: $stackTrace');
      return null;
    }
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

  /// Get issue by ID, checks local storage first, then fetches from database
  Future<Issue?> fetchIssueById(String id) async {
    try {
      // Check if issue exists locally
      final localIndex = storedIssues.indexWhere((it) => it.id == id);

      // If exists locally and fully loaded, return it
      if (localIndex != -1 && storedIssues[localIndex].fullyLoaded) {
        debugPrint('[fetchIssueById] Using cached issue: $id');
        return storedIssues[localIndex];
      }

      final token = await AuthHelper.getToken();

      if (token == null) {
        debugPrint('[fetchIssueById] No auth token');
        // Fallback to local storage if available
        if (localIndex != -1) {
          return storedIssues[localIndex];
        }
        return null;
      }

      final url = '$apiBaseUrl/issues/$id';
      debugPrint('[fetchIssueById] Fetching full issue from: $url');

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

        // Parse the full issue data
        final userId = data['user_id'] as String;
        final username = data['username'] as String?;
        final fullName = data['full_name'] as String?;
        final displayPictureUrl = data['display_picture_url'] as String?;

        // Create or update user in storedUsers
        final existingUserIndex = storedUsers.indexWhere((u) => u.id == userId);
        final user = models.User(
          id: userId,
          name: fullName ?? username ?? 'Unknown',
          imageUrl:
              'https://api.dicebear.com/9.x/pixel-art/png?seed=${Uri.encodeComponent(username ?? userId)}',
        );

        if (existingUserIndex == -1) {
          storedUsers.add(user);
        } else {
          storedUsers[existingUserIndex] = user;
        }

        // Process attachments from backend
        final List<String> fileIds = [];
        if (data['attachments'] != null) {
          final attachmentsList = data['attachments'] as List;
          for (final attachment in attachmentsList) {
            final attachmentId = attachment['attachment_id'] as String;
            final filePath = attachment['file_path'] as String;

            // Extract filename and extension from file_path
            final fileName = path.basename(filePath);
            final fileExtension = path
                .extension(fileName)
                .replaceFirst('.', '');
            final nameWithoutExt = path.basenameWithoutExtension(fileName);

            // Create FileAttachment object
            final fileAttachment = FileAttachment(
              id: attachmentId,
              name: nameWithoutExt,
              extension: fileExtension,
              uploadLink: getFullImageUrl(filePath),
            );

            // Add to storedFiles if not already present
            final existingFileIndex = storedFiles.indexWhere(
              (f) => f.id == attachmentId,
            );
            if (existingFileIndex == -1) {
              storedFiles.add(fileAttachment);
            } else {
              storedFiles[existingFileIndex] = fileAttachment;
            }

            fileIds.add(attachmentId);
          }
        }

        final issue = Issue(
          id: data['issue_id'] as String,
          title: data['title'] as String?,
          description: data['description'] as String?,
          postedBy: userId,
          upvoteCount: data['upvote_count'] as int?,
          commentCount: data['comment_count'] as int?,
          groupId: data['group_id'] as String?,
          displayPictureUrl: displayPictureUrl,
          imageUrl: displayPictureUrl != null
              ? getFullImageUrl(displayPictureUrl)
              : null,
          postedAt: data['posted_at'] != null
              ? DateTime.parse(data['posted_at'] as String)
              : null,
          fileIds: fileIds,
          attachments: data['attachments'] != null
              ? List<Map<String, dynamic>>.from(data['attachments'] as List)
              : null,
        );
        issue.fullyLoaded = true; // Mark as fully loaded

        // Update or add to local storage
        if (localIndex != -1) {
          storedIssues[localIndex] = issue;
        } else {
          storedIssues.add(issue);
        }

        notifyListeners();

        debugPrint('[fetchIssueById] Issue fetched and cached: ${issue.title}');
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
  /// Fetches from backend if user not in local storage.
  models.User getUserById(String id) {
    final user = storedUsers.firstWhere(
      (u) => u.id == id,
      orElse: () => models.User(id: id, name: 'Unknown'),
    );

    // If user is just a placeholder (only has id), fetch from backend
    if (user.name == 'Unknown' && !_loading.contains('user:$id')) {
      fetchUserById(id);
    }

    // Trigger background load of the user's image if we have a URL and it's not loaded yet.
    if (!user.loaded &&
        user.imageUrl != null &&
        !_loading.contains('user:$id')) {
      // Fire-and-forget; loadUserData manages _loading set to avoid duplicates.
      loadUserData(id);
    }

    return user;
  }

  /// Fetch user data from backend
  Future<void> fetchUserById(String id) async {
    if (_loading.contains('user:$id')) return;

    _loading.add('user:$id');
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        debugPrint('[fetchUserById] No auth token');
        return;
      }

      final url = '$apiBaseUrl/users/$id';
      debugPrint('[fetchUserById] Fetching user from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[fetchUserById] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final user = models.User(
          id: data['user_id'] as String,
          name: data['full_name'] as String,
          role: data['role_id'] as String,
          imageUrl:
              'https://api.dicebear.com/9.x/pixel-art/png?seed=${Uri.encodeComponent(data['username'] as String)}',
        );

        // Update or add to local storage
        final existingIndex = storedUsers.indexWhere((u) => u.id == id);
        if (existingIndex != -1) {
          storedUsers[existingIndex] = user;
        } else {
          storedUsers.add(user);
        }

        notifyListeners();
        debugPrint('[fetchUserById] User fetched: ${user.name}');
      } else {
        debugPrint('[fetchUserById] Error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('[fetchUserById] Exception: $e');
      debugPrint('[fetchUserById] Stack trace: $stackTrace');
    } finally {
      _loading.remove('user:$id');
    }
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

  // ============ GROUP API METHODS ============

  /// Fetch a group by ID from the backend
  Future<Group?> fetchGroupById(String id) async {
    try {
      final token = await AuthHelper.getToken();

      if (token == null) {
        debugPrint('[fetchGroupById] No auth token');
        return null;
      }

      final url = '$apiBaseUrl/groups/$id';
      debugPrint('[fetchGroupById] Fetching group from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[fetchGroupById] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final userId = data['owner_id'] as String;
        final username = data['username'] as String?;
        final fullName = data['full_name'] as String?;
        final displayPictureUrl = data['display_picture_url'] as String?;

        // Create or update user in storedUsers
        final existingUserIndex = storedUsers.indexWhere((u) => u.id == userId);
        final user = models.User(
          id: userId,
          name: fullName ?? username ?? 'Unknown',
          imageUrl:
              'https://api.dicebear.com/9.x/pixel-art/png?seed=${Uri.encodeComponent(username ?? userId)}',
        );

        if (existingUserIndex == -1) {
          storedUsers.add(user);
        } else {
          storedUsers[existingUserIndex] = user;
        }

        // Parse nested issues
        final issues = data['issues'] as List? ?? [];
        final issueIds = <String>[];
        for (final issueData in issues) {
          final issueId = issueData['issue_id'] as String;
          issueIds.add(issueId);

          // Create minimal issue objects for nested issues
          final localIndex = storedIssues.indexWhere((i) => i.id == issueId);
          final issue = Issue(
            id: issueId,
            title: issueData['title'] as String?,
            description: issueData['description'] as String?,
            postedBy: issueData['user_id'] as String,
            upvoteCount: issueData['upvote_count'] as int?,
            commentCount: issueData['comment_count'] as int?,
            groupId: id,
          );
          issue.fullyLoaded = false;

          if (localIndex != -1) {
            storedIssues[localIndex] = issue;
          } else {
            storedIssues.add(issue);
          }
        }

        final group = Group(
          id: data['group_id'] as String,
          title: data['name'] as String?,
          description: data['description'] as String?,
          postedBy: userId,
          upvoteCount: data['upvote_count'] as int?,
          commentCount: data['comment_count'] as int?,
          issueIds: issueIds,
          displayPictureUrl: displayPictureUrl,
          imageUrl: displayPictureUrl != null
              ? getFullImageUrl(displayPictureUrl)
              : null,
        );
        group.loaded = true;

        // Update or add to local storage
        final localIndex = storedGroups.indexWhere((g) => g.id == id);
        if (localIndex != -1) {
          storedGroups[localIndex] = group;
        } else {
          storedGroups.add(group);
        }

        notifyListeners();

        debugPrint('[fetchGroupById] Group fetched and cached: ${group.title}');
        return group;
      } else {
        debugPrint('[fetchGroupById] Error: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('[fetchGroupById] Exception: $e');
      debugPrint('[fetchGroupById] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Toggle upvote for a group
  Future<bool> toggleGroupUpvote(String groupId) async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        debugPrint('[toggleGroupUpvote] No auth token');
        return false;
      }

      final url = '$apiBaseUrl/groups/$groupId/upvote';
      debugPrint('[toggleGroupUpvote] Toggling upvote at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[toggleGroupUpvote] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final upvoted = data['upvoted'] as bool;
        final upvoteCount = data['upvote_count'] as int;

        // Update local group
        final group = storedGroups.firstWhere((g) => g.id == groupId);
        group.upvoteCount = upvoteCount;

        // Update cache
        _upvoteCache['group:$groupId'] = upvoted;

        notifyListeners();
        debugPrint(
          '[toggleGroupUpvote] Upvoted: $upvoted, Count: $upvoteCount',
        );
        return upvoted;
      } else {
        debugPrint('[toggleGroupUpvote] Error: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[toggleGroupUpvote] Exception: $e');
      debugPrint('[toggleGroupUpvote] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Check if current user has upvoted a group
  Future<bool> checkIfGroupUpvoted(String groupId) async {
    final cacheKey = 'group:$groupId';

    // Return cached value if available
    if (_upvoteCache.containsKey(cacheKey)) {
      return _upvoteCache[cacheKey]!;
    }

    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        return false;
      }

      // Fetch upvotes and check if current user is in the list
      final upvoters = await fetchUpvotesForGroup(groupId);
      final isUpvoted = upvoters.any((user) => user.id == loggedInUserId);

      // Cache the result
      _upvoteCache[cacheKey] = isUpvoted;

      return isUpvoted;
    } catch (e) {
      debugPrint('[checkIfGroupUpvoted] Exception: $e');
      return false;
    }
  }

  /// Fetch list of users who upvoted a group
  Future<List<models.User>> fetchUpvotesForGroup(String groupId) async {
    try {
      final token = await AuthHelper.getToken();
      if (token == null) {
        debugPrint('[fetchUpvotesForGroup] No auth token');
        return [];
      }

      final url = '$apiBaseUrl/groups/$groupId/upvotes';
      debugPrint('[fetchUpvotesForGroup] Fetching from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final upvotesJson = data['upvotes'] as List;

        final users = <models.User>[];
        for (final upvote in upvotesJson) {
          final user = models.User(
            id: upvote['user_id'] as String,
            name:
                upvote['full_name'] as String? ??
                upvote['username'] as String? ??
                'Unknown',
            imageUrl:
                'https://api.dicebear.com/9.x/pixel-art/png?seed=${Uri.encodeComponent(upvote['username'] as String? ?? upvote['user_id'] as String)}',
          );
          users.add(user);
        }

        return users;
      } else {
        debugPrint('[fetchUpvotesForGroup] Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[fetchUpvotesForGroup] Exception: $e');
      return [];
    }
  }

  /// Fetch comments for a group
  Future<void> fetchCommentsForGroup(String groupId) async {
    try {
      final token = await AuthHelper.getToken();

      if (token == null) {
        debugPrint('[fetchCommentsForGroup] No auth token');
        return;
      }

      final url = '$apiBaseUrl/groups/$groupId/comments';
      debugPrint('[fetchCommentsForGroup] Fetching comments from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        '[fetchCommentsForGroup] Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final commentsJson = data['comments'] as List;

        final commentIds = <String>[];

        for (final commentData in commentsJson) {
          final commentId = commentData['comment_id'] as String;
          final userId = commentData['user_id'] as String;
          final username = commentData['username'] as String?;
          final fullName = commentData['full_name'] as String?;

          // Create or update user
          final existingUserIndex = storedUsers.indexWhere(
            (u) => u.id == userId,
          );
          final user = models.User(
            id: userId,
            name: fullName ?? username ?? 'Unknown',
            imageUrl:
                'https://api.dicebear.com/9.x/pixel-art/png?seed=${Uri.encodeComponent(username ?? userId)}',
          );

          if (existingUserIndex == -1) {
            storedUsers.add(user);
          } else {
            storedUsers[existingUserIndex] = user;
          }

          // Create comment
          final comment = Comment(
            id: commentId,
            issueId: groupId, // Using issueId field for groupId
            postedBy: userId,
            content: commentData['content'] as String,
            postedAt: commentData['posted_at'] != null
                ? DateTime.parse(commentData['posted_at'] as String)
                : null,
          );

          // Add or update comment
          final existingCommentIndex = storedComments.indexWhere(
            (c) => c.id == commentId,
          );
          if (existingCommentIndex == -1) {
            storedComments.add(comment);
          } else {
            storedComments[existingCommentIndex] = comment;
          }

          commentIds.add(commentId);
        }

        // Update group with comment IDs
        final group = storedGroups.firstWhere((g) => g.id == groupId);
        group.commentIds = commentIds;

        notifyListeners();
        debugPrint(
          '[fetchCommentsForGroup] Loaded ${commentIds.length} comments',
        );
      } else {
        debugPrint('[fetchCommentsForGroup] Error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('[fetchCommentsForGroup] Exception: $e');
      debugPrint('[fetchCommentsForGroup] Stack trace: $stackTrace');
    }
  }

  /// Add a comment to a group
  Future<Comment?> addGroupComment(String groupId, String content) async {
    try {
      final token = await AuthHelper.getToken();

      if (token == null) {
        debugPrint('[addGroupComment] No auth token');
        return null;
      }

      final url = '$apiBaseUrl/groups/$groupId/comments';
      debugPrint('[addGroupComment] Posting comment to: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': content}),
      );

      debugPrint('[addGroupComment] Response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        final commentId = data['comment_id'] as String;
        final userId = data['user_id'] as String;
        final username = data['username'] as String?;
        final fullName = data['full_name'] as String?;

        // Create or update user
        final existingUserIndex = storedUsers.indexWhere((u) => u.id == userId);
        final user = models.User(
          id: userId,
          name: fullName ?? username ?? 'Unknown',
          imageUrl:
              'https://api.dicebear.com/9.x/pixel-art/png?seed=${Uri.encodeComponent(username ?? userId)}',
        );

        if (existingUserIndex == -1) {
          storedUsers.add(user);
        } else {
          storedUsers[existingUserIndex] = user;
        }

        // Create comment
        final comment = Comment(
          id: commentId,
          issueId: groupId, // Using issueId field for groupId
          postedBy: userId,
          content: data['content'] as String,
          postedAt: data['posted_at'] != null
              ? DateTime.parse(data['posted_at'] as String)
              : DateTime.now(),
        );

        // Add comment to stored comments
        storedComments.add(comment);

        // Update group with new comment
        final group = storedGroups.firstWhere((g) => g.id == groupId);
        group.commentIds = [...(group.commentIds ?? []), commentId];
        group.commentCount = (group.commentCount ?? 0) + 1;

        notifyListeners();
        debugPrint('[addGroupComment] Comment added successfully');

        return comment;
      } else {
        debugPrint('[addGroupComment] Error: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('[addGroupComment] Exception: $e');
      debugPrint('[addGroupComment] Stack trace: $stackTrace');
      return null;
    }
  }

  // ============ END GROUP API METHODS ============

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
