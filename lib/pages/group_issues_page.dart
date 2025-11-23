import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/widgets/group_issue_preview_tile.dart';

class GroupIssuesPage extends StatefulWidget {
  const GroupIssuesPage({super.key, required this.groupId});
  final String groupId;

  @override
  State<GroupIssuesPage> createState() => _GroupIssuesPageState();
}

class _GroupIssuesPageState extends State<GroupIssuesPage> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = Provider.of<LocalData>(context);
    final group = local.getGroupById(widget.groupId);

    return Scaffold(
      appBar: AppBar(title: Text('Group Issues')),
      body: ListView.builder(
        controller: _controller,
        itemCount: group.issueIds?.length ?? 0,
        itemBuilder: (ctx, i) {
          final id = group.issueIds![i];
          // Trigger loading for items as they appear
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!local.isLoading(id) && !local.getIssueById(id).loaded) {
              local.loadIssueData(id);
            }
          });
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            child: SizedBox(
              height: 120,
              child: GroupIssuePreviewTile(issueId: id, height: 100),
            ),
          );
        },
      ),
    );
  }
}
