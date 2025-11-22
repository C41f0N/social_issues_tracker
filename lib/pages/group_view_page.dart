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
    });
    // Listen to scroll updates to trigger UI rebuilds for parallax and header.
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final local = Provider.of<LocalData>(context);
    final group = local.getGroupById(widget.groupId);

    User? postedBy;

    debugPrint(widget.groupId);

    if (group.postedBy != null) {
      postedBy = local.getUserById(group.postedBy!);
    }

    return Scaffold(
      body: WithCustomHeader(
        child: Stack(
          children: [
            // Image
            Transform.translate(
              offset: Offset(
                0,
                scrollController.hasClients
                    ? scrollController.offset * -0.25
                    : 0,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Builder(
                  builder: (context) {
                    if (group.loaded && group.imageData != null) {
                      return Container(
                        child: Image.memory(
                          group.imageData!,
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width,
                        ),
                      );
                    }

                    // Ensure load is triggered (initState also requests it), local guards duplicates.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final local2 = Provider.of<LocalData>(
                        context,
                        listen: false,
                      );
                      local2.loadGroupData(group.id);
                    });

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(color: Colors.grey[350]),
                        const CircularProgressIndicator(),
                      ],
                    );
                  },
                ),
              ),
            ),

            SingleChildScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
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
                                group.postedBy != null &&
                                group.postedBy == local.loggedInUserId;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (canEdit)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => GroupEditPage(
                                              mode: GroupEditMode.edit,
                                              groupId: group.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                // Title
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
                                      // width: constraints.maxWidth * 0.2,
                                      child: Column(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                upvoted = !upvoted;
                                              });
                                            },
                                            child: Icon(
                                              upvoted
                                                  ? upvoteIconFilled
                                                  : upvoteIconOutlined,
                                            ),
                                          ),
                                          if (group.upvoteCount != null)
                                            SizedBox(height: 5),
                                          if (group.upvoteCount != null)
                                            Text(
                                              formatCompact(group.upvoteCount!),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
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

                                SizedBox(height: 30),

                                // Group Issues preview (first 2)
                                Text(
                                  "Group Issues",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                SizedBox(height: 10),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
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
                                        ...group.issueIds
                                            .take(2)
                                            .map(
                                              (id) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 6.0,
                                                    ),
                                                child: GroupIssuePreviewTile(
                                                  issueId: id,
                                                  height: 95,
                                                ),
                                              ),
                                            ),
                                        if (group.issueIds.length > 2)
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
                                                "View more",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge!
                                                    .copyWith(
                                                      color: Theme.of(context)
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
                                        builder: (_) =>
                                            CommentsDialogue(issueId: group.id),
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
                                                    EdgeInsetsGeometry.symmetric(
                                                      vertical: 5,
                                                    ),
                                                child: Text(
                                                  "View more",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge!
                                                      .copyWith(
                                                        color: Theme.of(context)
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
                                  "Group Files",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                SizedBox(height: 20),
                                SizedBox(
                                  height: 200,
                                  child: LayoutBuilder(
                                    builder: (context, constraints1) {
                                      double spaceBetween = 20;

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.red,
                                            ),
                                            width:
                                                constraints.maxWidth * 0.5 -
                                                spaceBetween * 0.5,
                                          ),

                                          SizedBox(
                                            width:
                                                constraints.maxWidth * 0.5 -
                                                spaceBetween * 0.5,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    color: Colors.red,
                                                  ),

                                                  width:
                                                      constraints.maxWidth *
                                                          0.5 -
                                                      spaceBetween * 0.5,

                                                  height:
                                                      constraints1.maxHeight *
                                                          0.5 -
                                                      spaceBetween * 0.5,
                                                ),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    color: Colors.red,
                                                  ),
                                                  width:
                                                      constraints.maxWidth *
                                                      0.45,
                                                  height:
                                                      constraints1.maxHeight *
                                                      0.49,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
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
                  Text("Group managed by"),
                  SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }
}
