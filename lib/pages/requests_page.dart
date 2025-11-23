import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/group_join_request.dart';

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Join Requests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Incoming'),
              Tab(text: 'Outgoing'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_IncomingRequestsTab(), _OutgoingRequestsTab()],
        ),
      ),
    );
  }
}

class _IncomingRequestsTab extends StatelessWidget {
  const _IncomingRequestsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalData>(
      builder: (context, local, child) {
        final requests = local.incomingRequestsForCurrentUser;

        if (requests.isEmpty) {
          return const Center(child: Text('No incoming requests.'));
        }

        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final r = requests[index];
            final issue = local.storedIssues.firstWhere(
              (i) => i.id == r.issueId,
            );
            final group = local.storedGroups.firstWhere(
              (g) => g.id == r.groupId,
            );

            final requesterName = r.requestedByGroup
                ? local.getUserById(group.postedBy ?? '').name ?? 'Someone'
                : local.getUserById(issue.postedBy ?? '').name ?? 'Someone';

            final canAct = local.canCurrentUserActOnRequest(r);

            return ListTile(
              title: Text(
                '${issue.title ?? 'Issue'} ↔ ${group.title ?? 'Group'}',
              ),
              subtitle: Text(
                'Requested by $requesterName on ${r.requestedAt.toLocal().toString().split(' ').first}',
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  _StatusChip(status: r.status),
                  if (canAct)
                    TextButton(
                      onPressed: () async {
                        await local.updateGroupJoinRequestStatus(
                          r.id,
                          GroupJoinRequestStatus.accepted,
                        );
                      },
                      child: const Text('Accept'),
                    ),
                  if (canAct)
                    TextButton(
                      onPressed: () async {
                        await local.updateGroupJoinRequestStatus(
                          r.id,
                          GroupJoinRequestStatus.declined,
                        );
                      },
                      child: const Text('Decline'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _OutgoingRequestsTab extends StatelessWidget {
  const _OutgoingRequestsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalData>(
      builder: (context, local, child) {
        final requests = local.outgoingRequestsForCurrentUser;

        if (requests.isEmpty) {
          return const Center(child: Text('No outgoing requests.'));
        }

        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final r = requests[index];
            final issue = local.storedIssues.firstWhere(
              (i) => i.id == r.issueId,
            );
            final group = local.storedGroups.firstWhere(
              (g) => g.id == r.groupId,
            );

            final targetName = r.requestedByGroup
                ? local.getUserById(issue.postedBy ?? '').name ?? 'Someone'
                : local.getUserById(group.postedBy ?? '').name ?? 'Someone';

            final canCancel = local.canCurrentUserCancelRequest(r);

            return ListTile(
              title: Text(
                '${issue.title ?? 'Issue'} ↔ ${group.title ?? 'Group'}',
              ),
              subtitle: Text(
                'Requested from $targetName on ${r.requestedAt.toLocal().toString().split(' ').first}',
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  _StatusChip(status: r.status),
                  if (canCancel)
                    TextButton(
                      onPressed: () async {
                        await local.updateGroupJoinRequestStatus(
                          r.id,
                          GroupJoinRequestStatus.cancelled,
                        );
                      },
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final GroupJoinRequestStatus status;

  Color _colorForStatus(BuildContext context) {
    switch (status) {
      case GroupJoinRequestStatus.pending:
        return Colors.orange;
      case GroupJoinRequestStatus.accepted:
        return Colors.green;
      case GroupJoinRequestStatus.declined:
        return Colors.red;
      case GroupJoinRequestStatus.cancelled:
        return Colors.grey;
    }
  }

  String _labelForStatus() {
    switch (status) {
      case GroupJoinRequestStatus.pending:
        return 'Pending';
      case GroupJoinRequestStatus.accepted:
        return 'Accepted';
      case GroupJoinRequestStatus.declined:
        return 'Declined';
      case GroupJoinRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_labelForStatus()),
      backgroundColor: _colorForStatus(context).withValues(alpha: 0.15),
      labelStyle: TextStyle(color: _colorForStatus(context)),
    );
  }
}
