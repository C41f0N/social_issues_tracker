import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/user.dart';
import 'package:social_issues_tracker/widgets/user_avatar.dart';
import 'package:social_issues_tracker/widgets/with_custom_header.dart';
import 'package:social_issues_tracker/pages/issue_view_page.dart';
import 'package:social_issues_tracker/pages/group_view_page.dart';

class UserViewPage extends StatefulWidget {
  const UserViewPage({super.key, required this.userId});

  final String userId;

  @override
  State<UserViewPage> createState() => _UserViewPageState();
}

class _UserViewPageState extends State<UserViewPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LocalData>(
      builder: (context, local, child) {
        User? user = local.getUserById(widget.userId);

        // Find issues and groups posted by this user
        final userIssues = local.storedIssues
            .where((it) => it.postedBy == widget.userId)
            .toList();
        final userGroups = local.storedGroups
            .where((g) => g.postedBy == widget.userId)
            .toList();

        return Scaffold(
          body: WithCustomHeader(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  UserAvatar(user: user, radius: 60),
                  const SizedBox(height: 16),
                  Text(
                    user.name ?? "Loading...",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      local.getRoleById(user.role ?? '').title ?? "",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Issues section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Managed Issues',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (userIssues.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('No issues created by this user.'),
                    )
                  else
                    ...userIssues.map((it) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          tileColor: Theme.of(context).colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          title: Text(it.title ?? 'Untitled'),
                          subtitle: Text(
                            it.description ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: SizedBox(
                            width: 72,
                            height: 72,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Builder(
                                builder: (context) {
                                  if (it.loaded && it.imageData != null) {
                                    return Image.memory(
                                      it.imageData!,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  // trigger load if needed
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (!it.loaded && !local.isLoading(it.id))
                                      local.loadIssueData(it.id);
                                  });
                                  return Container(color: Colors.grey[300]);
                                },
                              ),
                            ),
                          ),
                          onTap: () => context.pushTransition(
                            type: PageTransitionType.rightToLeft,
                            child: IssueViewPage(issueId: it.id),
                          ),
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 20),

                  // Groups section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Managed Groups',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (userGroups.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('No groups created by this user.'),
                    )
                  else
                    ...userGroups.map((g) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          tileColor: Theme.of(context).colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          title: Text(g.title ?? 'Untitled'),
                          subtitle: Text(
                            g.description ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: SizedBox(
                            width: 72,
                            height: 72,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Builder(
                                builder: (context) {
                                  if (g.loaded && g.imageData != null) {
                                    return Image.memory(
                                      g.imageData!,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (!g.loaded &&
                                        !local.isLoading(g.id, isGroup: true))
                                      local.loadGroupData(g.id);
                                  });
                                  return Container(color: Colors.grey[300]);
                                },
                              ),
                            ),
                          ),
                          onTap: () => context.pushTransition(
                            type: PageTransitionType.rightToLeft,
                            child: GroupViewPage(groupId: g.id),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
