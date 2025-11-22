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
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        _query = _controller.text.trim();
      });
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _tab = SearchTab.values[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = Provider.of<LocalData>(context);
    final theme = Theme.of(context);

    final q = _query.toLowerCase();

    bool matchesIssue(Issue i) {
      if (q.isEmpty) return true;
      final title = (i.title ?? '').toLowerCase();
      final desc = (i.description ?? '').toLowerCase();
      return title.contains(q) || desc.contains(q);
    }

    bool matchesGroup(Group g) {
      if (q.isEmpty) return true;
      final title = (g.title ?? '').toLowerCase();
      final desc = (g.description ?? '').toLowerCase();
      return title.contains(q) || desc.contains(q);
    }

    bool matchesUser(User u) {
      if (q.isEmpty) return true;
      final name = (u.name ?? '').toLowerCase();
      return name.contains(q);
    }

    final users = local.storedUsers.where(matchesUser).toList();
    final issues = local.storedIssues.where(matchesIssue).toList();
    final groups = local.storedGroups.where(matchesGroup).toList();

    List<_SearchEntry> all = [];
    all.addAll(issues.map((e) => _SearchEntry.issue(e)));
    all.addAll(groups.map((e) => _SearchEntry.group(e)));
    all.addAll(users.map((e) => _SearchEntry.user(e)));

    List<_SearchEntry> visibleEntries;
    switch (_tab) {
      case SearchTab.users:
        visibleEntries = users.map((e) => _SearchEntry.user(e)).toList();
        break;
      case SearchTab.issues:
        visibleEntries = issues.map((e) => _SearchEntry.issue(e)).toList();
        break;
      case SearchTab.groups:
        visibleEntries = groups.map((e) => _SearchEntry.group(e)).toList();
        break;
      case SearchTab.all:
      default:
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
        default:
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

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final e = entries[index];
        IconData icon;
        String title;
        String subtitle;
        String typeLabel;
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
                MaterialPageRoute(builder: (_) => IssueViewPage(issueId: i.id)),
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
                MaterialPageRoute(builder: (_) => GroupViewPage(groupId: g.id)),
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
