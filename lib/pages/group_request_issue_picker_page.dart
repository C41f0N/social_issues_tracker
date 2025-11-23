import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/issue.dart';

class GroupRequestIssuePickerPage extends StatelessWidget {
  const GroupRequestIssuePickerPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalData>(
      builder: (context, local, child) {
        final group = local.storedGroups.firstWhere((g) => g.id == groupId);
        final issues = local.storedIssues
            .where((i) => !(group.issueIds?.contains(i.id) ?? false))
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Select issue')),
          body: ListView.separated(
            itemCount: issues.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final Issue issue = issues[index];
              final canRequest = local.canCurrentUserRequestGroupToIncludeIssue(
                group.id,
                issue.id,
              );

              return ListTile(
                title: Text(issue.title ?? 'Untitled issue'),
                subtitle: Text(issue.description ?? ''),
                enabled: canRequest,
                onTap: !canRequest
                    ? null
                    : () async {
                        final result = await local.addGroupJoinRequest(
                          issueId: issue.id,
                          groupId: group.id,
                          requestedByGroup: true,
                        );

                        if (!context.mounted) return;

                        if (result != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Requested to include issue in "${group.title ?? 'group'}"',
                              ),
                            ),
                          );
                          Navigator.of(context).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to create request'),
                            ),
                          );
                        }
                      },
              );
            },
          ),
        );
      },
    );
  }
}
