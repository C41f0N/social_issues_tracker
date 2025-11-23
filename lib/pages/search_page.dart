import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/issue.dart';
import 'package:social_issues_tracker/data/models/group.dart';
import 'package:social_issues_tracker/data/models/user.dart';
import 'package:social_issues_tracker/pages/issue_view_page.dart';
import 'package:social_issues_tracker/pages/group_view_page.dart';
import 'package:social_issues_tracker/pages/user_view_page.dart';

enum SearchTab { all, users, issues, groups }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  String _query = '';
  SearchTab _tab = SearchTab.all;

  List<User> _users = [];
  List<Issue> _issues = [];
  List<Group> _groups = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _controller.text.trim();
      setState(() {
        _query = query;
      });
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _users = [];
          _issues = [];
          _groups = [];
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    final local = Provider.of<LocalData>(context, listen: false);

    String searchType = 'all';
    switch (_tab) {
      case SearchTab.users:
        searchType = 'users';
        break;
      case SearchTab.issues:
        searchType = 'issues';
        break;
      case SearchTab.groups:
        searchType = 'groups';
        break;
      case SearchTab.all:
        searchType = 'all';
        break;
    }

    final results = await local.search(query, type: searchType);

    if (mounted) {
      setState(() {
        _users = List<User>.from(results['users'] ?? []);
        _issues = List<Issue>.from(results['issues'] ?? []);
        _groups = List<Group>.from(results['groups'] ?? []);
        _isSearching = false;
      });
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _tab = SearchTab.values[index];
    });
    // Re-run search with new tab filter
    if (_query.isNotEmpty) {
      _performSearch(_query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    List<_SearchEntry> all = [];
    all.addAll(_issues.map((e) => _SearchEntry.issue(e)));
    all.addAll(_groups.map((e) => _SearchEntry.group(e)));
    all.addAll(_users.map((e) => _SearchEntry.user(e)));

    List<_SearchEntry> visibleEntries;
    switch (_tab) {
      case SearchTab.users:
        visibleEntries = _users.map((e) => _SearchEntry.user(e)).toList();
        break;
      case SearchTab.issues:
        visibleEntries = _issues.map((e) => _SearchEntry.issue(e)).toList();
        break;
      case SearchTab.groups:
        visibleEntries = _groups.map((e) => _SearchEntry.group(e)).toList();
        break;
      case SearchTab.all:
        visibleEntries = all;
        break;
    }

    return DefaultTabController(
      length: SearchTab.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search'),
          bottom: TabBar(
            onTap: _onTabChanged,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Users'),
              Tab(text: 'Issues'),
              Tab(text: 'Groups'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Search issues, groups, and users',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(child: _buildResultsList(theme, visibleEntries)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme, List<_SearchEntry> entries) {
    if (_query.isEmpty) {
      return Center(
        child: Text(
          'Type to search issues, groups, and users.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (entries.isEmpty) {
      String label;
      switch (_tab) {
        case SearchTab.users:
          label = 'users';
          break;
        case SearchTab.issues:
          label = 'issues';
          break;
        case SearchTab.groups:
          label = 'groups';
          break;
        case SearchTab.all:
          label = 'results';
          break;
      }

      return Center(
        child: Text(
          'No $label found for "$_query".',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_query.isNotEmpty) {
          await _performSearch(_query);
        }
      },
      child: ListView.separated(
        itemCount: entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final e = entries[index];
          IconData icon;
          String title;
          String subtitle;
          VoidCallback onTap;

          switch (e.kind) {
            case _SearchKind.user:
              final u = e.user!;
              icon = Icons.person;
              title = u.name ?? 'Unknown user';
              subtitle = 'User';
              onTap = () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => UserViewPage(userId: u.id)),
                );
              };
              break;
            case _SearchKind.issue:
              final i = e.issue!;
              icon = Icons.report;
              title = i.title ?? 'Untitled issue';
              subtitle = 'Issue';
              onTap = () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => IssueViewPage(issueId: i.id),
                  ),
                );
              };
              break;
            case _SearchKind.group:
              final g = e.group!;
              icon = Icons.folder_copy;
              title = g.title ?? 'Untitled group';
              subtitle = 'Group';
              onTap = () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GroupViewPage(groupId: g.id),
                  ),
                );
              };
              break;
          }

          return ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            onTap: onTap,
          );
        },
      ),
    );
  }
}

enum _SearchKind { user, issue, group }

class _SearchEntry {
  final _SearchKind kind;
  final User? user;
  final Issue? issue;
  final Group? group;

  _SearchEntry._(this.kind, {this.user, this.issue, this.group});

  factory _SearchEntry.user(User u) =>
      _SearchEntry._(_SearchKind.user, user: u);

  factory _SearchEntry.issue(Issue i) =>
      _SearchEntry._(_SearchKind.issue, issue: i);

  factory _SearchEntry.group(Group g) =>
      _SearchEntry._(_SearchKind.group, group: g);
}
