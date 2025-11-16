import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:social_issues_tracker/data/models/issue.dart';
import 'package:social_issues_tracker/data/models/user.dart';

class LocalData with ChangeNotifier {
  List<User> storedUsers = [
    User(id: "user1", name: "Sarim Ahmed", role: "1"),
    User(id: "user2", name: "Aisha Khan", role: "2"),
    User(id: "user3", name: "Daniel Park", role: "2"),
    User(id: "user4", name: "Maria Gomez", role: "3"),
  ];

  List<Issue> storedIssues = [
    Issue(
      id: "issue1",
      title: "Lack of street lighting",
      description:
          "Several streets in the north end are poorly lit at night causing safety concerns.",
      upvoteCount: 24123,
      commentCount: 5,
      postedBy: "user2",
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
      imageUrl: 'https://picsum.photos/id/1025/800/1200',
    ),
    Issue(
      id: "issue3",
      title: "Broken playground equipment",
      description:
          "The swings at Central Park are broken and pose a hazard to children.",
      upvoteCount: 32,
      commentCount: 10,
      postedBy: "user4",
      imageUrl: 'https://picsum.photos/id/1035/800/1200',
    ),
    Issue(
      id: "issue4",
      title: "Illegal parking on sidewalks",
      description:
          "Cars regularly block sidewalks, forcing pedestrians into the street.",
      upvoteCount: 18,
      commentCount: 4,
      postedBy: "user3",
      imageUrl: 'https://picsum.photos/id/1045/800/1200',
    ),
    Issue(
      id: "issue5",
      title: "Water supply interruptions",
      description: "Frequent water outages in Block C for the past two weeks.",
      upvoteCount: 40,
      commentCount: 12,
      postedBy: "user2",
      imageUrl: 'https://picsum.photos/id/1055/800/1200',
    ),
    Issue(
      id: "issue6",
      title: "Graffiti on public buildings",
      description:
          "New graffiti has appeared on the library facade; needs cleaning.",
      upvoteCount: 9,
      commentCount: 1,
      postedBy: "user4",
      imageUrl: 'https://picsum.photos/id/1065/800/1200',
    ),
    Issue(
      id: "issue7",
      title: "No recycling pickup",
      description:
          "Recycling hasn't been collected in our area since last month.",
      upvoteCount: 22,
      commentCount: 6,
      postedBy: "user1",
      imageUrl: 'https://picsum.photos/id/1075/800/1200',
    ),
    Issue(
      id: "issue8",
      title: "Potholes on Main St.",
      description:
          "Multiple potholes causing damage to vehicles and slowing traffic.",
      upvoteCount: 55,
      commentCount: 20,
      postedBy: "user3",
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
      imageUrl: 'https://picsum.photos/id/1095/800/1200',
    ),
    Issue(
      id: "issue10",
      title: "No bicycle lanes",
      description:
          "Cyclists have no dedicated lanes on the new road expansion.",
      upvoteCount: 27,
      commentCount: 7,
      postedBy: "user4",
      imageUrl: 'https://picsum.photos/id/1105/800/1200',
    ),
  ];

  // Track in-progress loads so we don't duplicate requests.
  final Set<String> _loading = {};

  Future<void> loadIssueData(String id) async {
    final issue = storedIssues.firstWhere(
      (it) => it.id == id,
      orElse: () => Issue(id: id),
    );

    if (issue.loaded || issue.imageData != null) return;
    if (_loading.contains(id)) return;
    if (issue.imageUrl == null) return;

    _loading.add(id);
    try {
      final uri = Uri.parse(issue.imageUrl!);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      issue.imageData = Uint8List.fromList(bytes);
      issue.loaded = true;
      notifyListeners();
    } catch (e) {
      // ignore errors for now; keep loaded=false
    } finally {
      _loading.remove(id);
    }
  }
}
