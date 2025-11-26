import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/constants.dart';
import 'package:social_issues_tracker/data/models/user.dart' as models;
import 'package:social_issues_tracker/pages/user_view_page.dart';
import 'package:social_issues_tracker/utils.dart';
import 'package:social_issues_tracker/widgets/comment_widget.dart';
import 'package:social_issues_tracker/widgets/comments_dialogue.dart';
import 'package:social_issues_tracker/widgets/user_avatar.dart';
import 'package:social_issues_tracker/widgets/with_custom_header.dart';
import 'package:social_issues_tracker/widgets/issue_image.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/issue.dart';
import 'package:social_issues_tracker/data/models/file_attachment.dart';
import 'package:social_issues_tracker/pages/issue_edit_page.dart';
import 'package:social_issues_tracker/pages/issue_join_group_picker_page.dart';

class IssueViewPage extends StatefulWidget {
  const IssueViewPage({super.key, required this.issueId});

  final String issueId;

  @override
  State<IssueViewPage> createState() => _IssueViewPageState();
}

class _IssueViewPageState extends State<IssueViewPage>
    with SingleTickerProviderStateMixin {
  ScrollController scrollController = ScrollController();

  bool upvoted = false;
  bool descriptionExpanded = false;
  bool _loading = true;

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
    // Trigger loading of the issue from database first, then image
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIssue();
      _checkUpvoteStatus();
    });
    // Listen to scroll updates to trigger UI rebuilds for parallax and header.
    scrollController.addListener(_onScroll);
  }

  Future<void> _checkUpvoteStatus() async {
    final local = Provider.of<LocalData>(context, listen: false);
    final isUpvoted = await local.checkIfUpvoted(widget.issueId);

    if (mounted) {
      setState(() {
        upvoted = isUpvoted;
      });
    }
  }

  Future<void> _toggleUpvote() async {
    final local = Provider.of<LocalData>(context, listen: false);

    // Optimistic flip so icon updates immediately
    if (mounted) {
      setState(() {
        upvoted = !upvoted;
      });
    }

    final newUpvoteState = await local.toggleIssueUpvote(widget.issueId);

    if (mounted) {
      setState(() {
        upvoted = newUpvoteState;
      });
    }
  }

  Future<void> _loadIssue() async {
    final local = Provider.of<LocalData>(context, listen: false);

    // Fetch issue from database
    await local.fetchIssueById(widget.issueId);

    if (mounted) {
      setState(() {
        _loading = false;
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
    final issue = local.storedIssues.firstWhere(
      (it) => it.id == widget.issueId,
      orElse: () => Issue(id: widget.issueId),
    );

    models.User? postedBy;

    if (issue.postedBy != null) {
      postedBy = local.getUserById(issue.postedBy!);
    }

    // Show loading indicator while fetching
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    print(issue.displayPictureUrl);

    print(issue.attachments);

    return Scaffold(
      body: WithCustomHeader(
        child: Stack(
          children: [
            // Image
            Transform.translate(
              offset: Offset(
                0,
                (scrollController.hasClients
                    ? scrollController.offset * -0.25
                    : 0),
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: IssueImage(
                  imageUrl: issue.imageUrl,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.4,
                ),
              ),
            ),

            RefreshIndicator(
              onRefresh: () => local.fetchIssueById(widget.issueId),
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4 - 20,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final canEdit =
                                  issue.postedBy != null &&
                                  issue.postedBy == local.loggedInUserId;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Old edit/delete buttons consolidated into options menu.
                                  // Request action moved into options menu; keep UI concise.
                                  // Title
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: constraints.maxWidth * 0.8,
                                        child: AutoSizeText(
                                          issue.title ?? 'Untitled',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineLarge,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                      SizedBox(
                                        // width: constraints.maxWidth * 0.2,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Options menu (shows edit/delete/request)
                                            if (canEdit)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                ),
                                                onPressed: () {
                                                  final local =
                                                      Provider.of<LocalData>(
                                                        context,
                                                        listen: false,
                                                      );
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
                                                                      builder: (_) => IssueEditPage(
                                                                        mode: IssueEditMode
                                                                            .edit,
                                                                        issueId:
                                                                            issue.id,
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
                                                                        'Delete Issue',
                                                                      ),
                                                                      content:
                                                                          const Text(
                                                                            'Are you sure you want to delete this issue? This action cannot be undone.',
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
                                                                        await local.deleteIssue(
                                                                          widget
                                                                              .issueId,
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
                                                                            'Failed to delete issue',
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                },
                                                              ),
                                                            ListTile(
                                                              leading: const Icon(
                                                                Icons.group_add,
                                                              ),
                                                              title: const Text(
                                                                'Request to join group',
                                                              ),
                                                              onTap: () {
                                                                Navigator.of(
                                                                  ctx,
                                                                ).pop();
                                                                Navigator.of(
                                                                  context,
                                                                ).push(
                                                                  MaterialPageRoute(
                                                                    builder: (_) =>
                                                                        IssueJoinGroupPickerPage(
                                                                          issueId:
                                                                              issue.id,
                                                                        ),
                                                                  ),
                                                                );
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
                                                if (issue.upvoteCount != null)
                                                  SizedBox(width: 8),
                                                if (issue.upvoteCount != null)
                                                  Text(
                                                    formatCompact(
                                                      issue.upvoteCount!,
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

                                  SizedBox(height: 30),

                                  // Details
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        descriptionExpanded =
                                            !descriptionExpanded;
                                      });
                                    },
                                    child: Text(
                                      issue.description ?? '',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                      overflow: descriptionExpanded
                                          ? null
                                          : TextOverflow.ellipsis,
                                      maxLines: descriptionExpanded ? null : 2,
                                    ),
                                  ),

                                  SizedBox(height: 30),

                                  Text(
                                    "Comments",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),

                                  SizedBox(height: 10),
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
                                            issueId: issue.id,
                                          ),
                                        );
                                      },
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          List<String> comments = local
                                              .getCommentsIdsForIssue(issue.id);

                                          // print(comments.map((x) => x.));

                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                ...List.generate(
                                                  comments.length > 2
                                                      ? 2
                                                      : comments.length,
                                                  (i) => Padding(
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
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      EdgeInsetsGeometry.symmetric(
                                                        vertical: 5,
                                                      ),
                                                  child: Text(
                                                    "View more",
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

                                  SizedBox(height: 30),
                                  // Files viewer
                                  Text(
                                    "Issue Files",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  SizedBox(height: 20),
                                  Builder(
                                    builder: (_) {
                                      final fileIds = issue.fileIds;
                                      if (fileIds.isEmpty) {
                                        return Text(
                                          "No files attached.",
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
                                        children: fileIds.map((fid) {
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
                                                // Approx half width minus spacing for nicer layout
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

                    SizedBox(height: 20),
                    Text("Issue managed by"),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: issue.postedBy != null
                          ? () {
                              context.pushTransition(
                                type: PageTransitionType.rightToLeft,
                                child: UserViewPage(userId: issue.postedBy!),
                              );
                            }
                          : null,
                      child: Column(
                        children: [
                          UserAvatar(user: postedBy, radius: 50),
                          SizedBox(height: 10),
                          Text(
                            postedBy != null ? postedBy.name ?? "user" : "user",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
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
