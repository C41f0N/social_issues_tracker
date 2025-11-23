// Wall item tile that renders either an Issue or a Group depending on `isGroup`.

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/auth/auth_notifier.dart';
import 'package:social_issues_tracker/constants.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/pages/group_view_page.dart';
import 'package:social_issues_tracker/pages/issue_view_page.dart';
import 'package:social_issues_tracker/widgets/issue_image.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/issue.dart';

import 'package:social_issues_tracker/data/models/user.dart' as models;
import 'package:social_issues_tracker/data/models/group.dart';
import 'package:social_issues_tracker/utils.dart';
import 'package:social_issues_tracker/widgets/comments_dialogue.dart';

class IssueTile extends StatefulWidget {
  const IssueTile({
    super.key,
    this.width,
    required this.height,
    required this.itemId,
    this.isGroup = false,
  });

  final double height;
  final double? width;
  final String itemId;
  final bool isGroup;

  @override
  State<IssueTile> createState() => _IssueTileState();
}

class _IssueTileState extends State<IssueTile> {
  bool upvoted = false;

  @override
  Widget build(BuildContext context) {
    final local = Provider.of<LocalData>(context);
    final isGroup = widget.isGroup;
    final Issue? issue = isGroup ? null : local.getIssueById(widget.itemId);
    final Group? group = isGroup ? local.getGroupById(widget.itemId) : null;

    final title = isGroup
        ? (group?.title ?? 'Untitled')
        : (issue?.title ?? 'Untitled');
    final upvoteCount = isGroup ? group?.upvoteCount : issue?.upvoteCount;
    final commentCount = isGroup ? group?.commentCount : issue?.commentCount;
    final description = isGroup ? group?.description : issue?.description;
    models.User? postedBy;

    if ((isGroup && group != null && group.postedBy != null) ||
        (!isGroup && issue != null && issue.postedBy != null)) {
      postedBy = local.getUserById(
        (isGroup ? group!.postedBy : issue!.postedBy)!,
      );
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: GestureDetector(
        onTap: () {
          context.pushTransition(
            type: PageTransitionType.rightToLeft,
            child: isGroup
                ? GroupViewPage(groupId: widget.itemId)
                : IssueViewPage(issueId: widget.itemId),
          );
        },
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: AlignmentGeometry.bottomCenter,
                children: [
                  // Image area
                  Container(
                    color: Colors.grey[400],
                    height: constraints.maxHeight,
                    child: IssueImage(
                      imageUrl: isGroup ? group?.imageUrl : issue?.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),

                  // Gradient overlay with title / actions
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 1),
                        ],
                        stops: [0, 0.4, 1],
                        begin: AlignmentGeometry.topCenter,
                        end: AlignmentGeometry.bottomCenter,
                      ),
                    ),
                    height: constraints.maxHeight * 0.45,
                    child: Container(
                      alignment: AlignmentGeometry.bottomCenter,
                      child: LayoutBuilder(
                        builder: (context, constraints1) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints1.maxWidth * 0.05,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      alignment: Alignment.bottomLeft,
                                      width: constraints1.maxWidth * 0.7,
                                      child: Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineMedium,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                upvoted = !upvoted;
                                              });
                                            },
                                            child: Column(
                                              children: [
                                                Icon(
                                                  upvoted
                                                      ? upvoteIconFilled
                                                      : upvoteIconOutlined,
                                                ),
                                                if (upvoteCount != null)
                                                  SizedBox(height: 2),
                                                if (upvoteCount != null)
                                                  Text(
                                                    formatCompact(upvoteCount),
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.labelSmall,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 15),
                                          GestureDetector(
                                            onTap: () {
                                              debugPrint('Open comments.');
                                              showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    CommentsDialogue(
                                                      issueId: widget.itemId,
                                                    ),
                                              );
                                            },
                                            child: Column(
                                              children: [
                                                Icon(Icons.comment),
                                                if (commentCount != null)
                                                  SizedBox(height: 2),
                                                if (commentCount != null)
                                                  Text(
                                                    formatCompact(commentCount),
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.labelSmall,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 70),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 3),
                                Container(
                                  height: constraints1.maxHeight * 0.1,
                                  child: Row(
                                    children: [
                                      // Group Indicator
                                      if (widget.isGroup)
                                        Opacity(
                                          opacity: 0.8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            child: Text(
                                              "Grouped Issues",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
                                            ),
                                          ),
                                        ),

                                      if (widget.isGroup) SizedBox(width: 5),

                                      // Divider point
                                      if (widget.isGroup)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                            borderRadius: BorderRadius.circular(
                                              90,
                                            ),
                                          ),
                                          height: 5,
                                          width: 5,
                                        ),

                                      SizedBox(width: 5),

                                      // Posted by
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Icon(Icons.person, size: 15),
                                          SizedBox(width: 5),
                                          Transform.translate(
                                            offset: const Offset(0, 1),
                                            child: Text(
                                              postedBy!.name ?? "",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(width: 2),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 5),
                                Container(
                                  alignment: Alignment.topLeft,
                                  height: constraints1.maxHeight * 0.1,
                                  child: Text(
                                    description ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(color: Colors.grey[600]),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                                SizedBox(height: 80),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
