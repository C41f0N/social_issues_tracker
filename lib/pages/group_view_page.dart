import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/constants.dart';
import 'package:social_issues_tracker/data/models/user.dart';
import 'package:social_issues_tracker/pages/group_issues_page.dart';
import 'package:social_issues_tracker/pages/user_view_page.dart';
import 'package:social_issues_tracker/utils.dart';
import 'package:social_issues_tracker/widgets/comment_widget.dart';
import 'package:social_issues_tracker/widgets/comments_dialogue.dart';
import 'package:social_issues_tracker/widgets/user_avatar.dart';
import 'package:social_issues_tracker/widgets/with_custom_header.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/widgets/group_issue_preview_tile.dart';
import 'package:social_issues_tracker/pages/group_edit_page.dart';
import 'package:social_issues_tracker/data/models/file_attachment.dart';
import 'package:social_issues_tracker/data/models/group.dart';

class GroupViewPage extends StatefulWidget {
  const GroupViewPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupViewPage> createState() => _GroupViewPageState();
}

class _GroupViewPageState extends State<GroupViewPage>
    with SingleTickerProviderStateMixin {
  ScrollController scrollController = ScrollController();

  bool upvoted = false;
  bool descriptionExpanded = false;

  @override
  void dispose() {
    // Remove scroll listener (if attached) then dispose controller.
    try {
      scrollController.removeListener(_onScroll);
    } catch (_) {}
    scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Trigger loading of the group image as soon as the page is created.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final local = Provider.of<LocalData>(context, listen: false);
      local.loadGroupData(widget.groupId);
      local.fetchGroupById(widget.groupId);
      _checkUpvoteStatus();
      _loadComments();
    });
    // Listen to scroll updates to trigger UI rebuilds for parallax and header.
    scrollController.addListener(_onScroll);
  }

  void _checkUpvoteStatus() async {
    final local = Provider.of<LocalData>(context, listen: false);
    final isUpvoted = await local.checkIfGroupUpvoted(widget.groupId);
    if (mounted) {
      setState(() {
        upvoted = isUpvoted;
      });
    }
  }

  void _loadComments() async {
    final local = Provider.of<LocalData>(context, listen: false);
    await local.fetchCommentsForGroup(widget.groupId);
  }

  Future<void> _toggleUpvote() async {
    final local = Provider.of<LocalData>(context, listen: false);

    // Optimistic flip so icon updates immediately
    if (mounted) {
      setState(() {
        upvoted = !upvoted;
      });
    }

    final newUpvoted = await local.toggleGroupUpvote(widget.groupId);
    if (mounted) {
      setState(() {
        upvoted = newUpvoted;
      });
    }
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final local = Provider.of<LocalData>(context);
    final group = local.storedGroups.firstWhere(
      (g) => g.id == widget.groupId,
      orElse: () => Group(id: widget.groupId),
    );

    User? postedBy;
    if (group.postedBy != null) {
      postedBy = local.getUserById(group.postedBy!);
    }

    // No heavy loading state here; show basic scaffold while data resolves
    return Scaffold(
      body: WithCustomHeader(
        child: Stack(
          children: [
            // Optional header image (parallax)
            Transform.translate(
              offset: Offset(
                0,
                (scrollController.hasClients
                    ? scrollController.offset * -0.25
                    : 0),
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.28,
                child: group.imageUrl != null
                    ? Image.network(group.imageUrl!, fit: BoxFit.cover)
                    : Container(),
              ),
            ),

            RefreshIndicator(
              onRefresh: () async {
                await local.fetchGroupById(widget.groupId);
              },
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.28 - 20,
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.72,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final canEdit =
                                  group.postedBy != null &&
                                  group.postedBy == local.loggedInUserId;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Title row with options and upvote
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: constraints.maxWidth * 0.8,
                                        child: AutoSizeText(
                                          group.title ?? 'Untitled',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineLarge,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                      SizedBox(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Options menu (shows edit/delete)
                                            if (canEdit)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                ),
                                                onPressed: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    builder: (ctx) {
                                                      return SafeArea(
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            if (canEdit)
                                                              ListTile(
                                                                leading:
                                                                    const Icon(
                                                                      Icons
                                                                          .edit,
                                                                    ),
                                                                title:
                                                                    const Text(
                                                                      'Edit',
                                                                    ),
                                                                onTap: () {
                                                                  Navigator.of(
                                                                    ctx,
                                                                  ).pop();
                                                                  Navigator.of(
                                                                    context,
                                                                  ).push(
                                                                    MaterialPageRoute(
                                                                      builder: (_) => GroupEditPage(
                                                                        mode: GroupEditMode
                                                                            .edit,
                                                                        groupId:
                                                                            group.id,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            if (canEdit)
                                                              ListTile(
                                                                leading: const Icon(
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                                title:
                                                                    const Text(
                                                                      'Delete',
                                                                    ),
                                                                onTap: () async {
                                                                  Navigator.of(
                                                                    ctx,
                                                                  ).pop();
                                                                  final confirmed = await showDialog<bool>(
                                                                    context:
                                                                        context,
                                                                    builder: (c) => AlertDialog(
                                                                      title: const Text(
                                                                        'Delete Group',
                                                                      ),
                                                                      content:
                                                                          const Text(
                                                                            'Are you sure you want to delete this group? This action cannot be undone.',
                                                                          ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.of(c).pop(
                                                                            false,
                                                                          ),
                                                                          child: const Text(
                                                                            'Cancel',
                                                                          ),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed: () => Navigator.of(c).pop(
                                                                            true,
                                                                          ),
                                                                          child: const Text(
                                                                            'Delete',
                                                                          ),
                                                                          style: TextButton.styleFrom(
                                                                            foregroundColor:
                                                                                Colors.red,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                  if (confirmed ==
                                                                      true) {
                                                                    final success =
                                                                        await local.deleteGroup(
                                                                          widget
                                                                              .groupId,
                                                                        );
                                                                    if (success &&
                                                                        context
                                                                            .mounted) {
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop();
                                                                    } else if (context
                                                                        .mounted) {
                                                                      ScaffoldMessenger.of(
                                                                        context,
                                                                      ).showSnackBar(
                                                                        const SnackBar(
                                                                          content: Text(
                                                                            'Failed to delete group',
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                },
                                                              ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            Column(
                                              children: [
                                                GestureDetector(
                                                  onTap: _toggleUpvote,
                                                  child: upvoteIcon(upvoted),
                                                ),
                                                if (group.upvoteCount != null)
                                                  SizedBox(width: 8),
                                                if (group.upvoteCount != null)
                                                  Text(
                                                    formatCompact(
                                                      group.upvoteCount!,
                                                    ),
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.labelSmall,
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 30),

                                  // Details
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        descriptionExpanded =
                                            !descriptionExpanded;
                                      });
                                    },
                                    child: Text(
                                      group.description ?? '',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                      overflow: descriptionExpanded
                                          ? null
                                          : TextOverflow.ellipsis,
                                      maxLines: descriptionExpanded ? null : 2,
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // Group Issues preview (first 2)
                                  Text(
                                    'Group Issues',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 10),
                                  if (group.issueIds?.isEmpty ?? true)
                                    Text(
                                      'No issues in this group yet.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .color!
                                                .withValues(alpha: 0.7),
                                          ),
                                    )
                                  else
                                    Container(
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.8,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            ...(group.issueIds
                                                    ?.take(2)
                                                    .map(
                                                      (id) => Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 6.0,
                                                            ),
                                                        child:
                                                            GroupIssuePreviewTile(
                                                              issueId: id,
                                                              height: 95,
                                                            ),
                                                      ),
                                                    ) ??
                                                []),
                                            if ((group.issueIds?.length ?? 0) >
                                                2)
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          GroupIssuesPage(
                                                            groupId: group.id,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8.0,
                                                      ),
                                                  child: Text(
                                                    'View more',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge!
                                                        .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .labelLarge!
                                                                  .color!
                                                                  .withValues(
                                                                    alpha: 0.8,
                                                                  ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 30),

                                  Text(
                                    'Comments',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 10),

                                  // Comments
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => CommentsDialogue(
                                            issueId: group.id,
                                            isGroup: true,
                                          ),
                                        );
                                      },
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final commentsAll = local
                                              .getCommentsIdsForIssue(group.id);
                                          final comments = commentsAll
                                              .take(2)
                                              .toList();

                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                ...List.generate(
                                                  comments.length,
                                                  (i) {
                                                    return Padding(
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                            0,
                                                            i == 0 ? 10 : 10,
                                                            0,
                                                            i == 3 - 1 ? 0 : 10,
                                                          ),
                                                      child: CommentWidget(
                                                        commentId: comments[i],
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 5,
                                                      ),
                                                  child: Text(
                                                    'View more',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge!
                                                        .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .labelLarge!
                                                                  .color!
                                                                  .withValues(
                                                                    alpha: 0.8,
                                                                  ),
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // Files viewer
                                  Text(
                                    'Group Files',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 20),
                                  Builder(
                                    builder: (_) {
                                      final fileIds = group.fileIds;
                                      if (fileIds?.isEmpty ?? true) {
                                        return Text(
                                          'No files attached.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .color!
                                                    .withValues(alpha: 0.7),
                                              ),
                                        );
                                      }

                                      IconData _iconForExt(String ext) {
                                        switch (ext.toLowerCase()) {
                                          case 'pdf':
                                            return Icons.picture_as_pdf;
                                          case 'jpg':
                                          case 'jpeg':
                                          case 'png':
                                          case 'gif':
                                            return Icons.image;
                                          case 'mp4':
                                          case 'mov':
                                          case 'avi':
                                            return Icons.videocam;
                                          case 'mp3':
                                          case 'wav':
                                            return Icons.audiotrack;
                                          default:
                                            return Icons.insert_drive_file;
                                        }
                                      }

                                      return Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: fileIds!.map((fid) {
                                          final FileAttachment f = local
                                              .getFileById(fid);
                                          final icon = _iconForExt(f.extension);
                                          return GestureDetector(
                                            onTap: () {
                                              if (f.uploadLink.isNotEmpty) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Pretend opening ${f.uploadLink}',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              constraints: BoxConstraints(
                                                maxWidth:
                                                    constraints.maxWidth * 0.47,
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.25),
                                                ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    icon,
                                                    size: 28,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          f.name,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleSmall,
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          f.extension
                                                              .toUpperCase(),
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color: Theme.of(
                                                                  context,
                                                                ).colorScheme.secondary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        height: 2,
                        width: MediaQuery.of(context).size.width * 0.6,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text('Group managed by'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: group.postedBy != null
                          ? () {
                              context.pushTransition(
                                type: PageTransitionType.rightToLeft,
                                child: UserViewPage(userId: group.postedBy!),
                              );
                            }
                          : null,
                      child: Column(
                        children: [
                          UserAvatar(user: postedBy, radius: 50),
                          const SizedBox(height: 10),
                          Text(
                            postedBy != null ? postedBy.name ?? 'user' : 'user',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
