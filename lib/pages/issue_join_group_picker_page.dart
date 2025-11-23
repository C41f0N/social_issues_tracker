import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/group.dart';

class IssueJoinGroupPickerPage extends StatelessWidget {
  const IssueJoinGroupPickerPage({super.key, required this.issueId});

  final String issueId;

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalData>(
      builder: (context, local, child) {
        final issue = local.storedIssues.firstWhere((i) => i.id == issueId);
        final groups = local.storedGroups
            .where((g) => !g.issueIds.contains(issueId))
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Select group')),
          body: ListView.separated(
            itemCount: groups.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final Group group = groups[index];
              final canRequest = local.canCurrentUserRequestIssueToJoinGroup(
                issue.id,
                group.id,
              );

              return ListTile(
                title: Text(group.title ?? 'Untitled group'),
                subtitle: Text(group.description ?? ''),
                enabled: canRequest,
                onTap: !canRequest
                    ? null
                    : () {
                        local.addGroupJoinRequest(
                          issueId: issue.id,
                          groupId: group.id,
                          requestedByGroup: false,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Requested for issue to join "${group.title ?? 'group'}"',
                            ),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
              );
            },
          ),
        );
      },
    );
  }
}
