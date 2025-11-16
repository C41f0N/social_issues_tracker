// removed unused dart:math import

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/constants.dart';
import 'package:social_issues_tracker/pages/issue_view_page.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/issue.dart';
import 'package:social_issues_tracker/utils.dart';

class IssueTile extends StatefulWidget {
  const IssueTile({
    super.key,
    this.width,
    required this.height,
    required this.issueId,
  });

  @override
  State<IssueTile> createState() => _IssueTileState();

  final double height;
  final double? width;
  final String issueId;
}

class _IssueTileState extends State<IssueTile> {
  bool upvoted = false;

  @override
  Widget build(BuildContext context) {
    final local = Provider.of<LocalData>(context);
    final issue = local.storedIssues.firstWhere(
      (it) => it.id == widget.issueId,
      orElse: () => Issue(id: widget.issueId),
    );

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: GestureDetector(
        onTap: () {
          context.pushTransition(
            type: PageTransitionType.rightToLeft,
            child: IssueViewPage(issueId: widget.issueId),
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
                  Container(
                    color: Colors.grey[400],
                    height: constraints.maxHeight * 1,
                    child: Builder(
                      builder: (context) {
                        // If image data already loaded, show it; otherwise show placeholder
                        if (issue.loaded && issue.imageData != null) {
                          return Image.memory(
                            issue.imageData!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          );
                        }

                        // Trigger load after frame (LocalData guards against duplicate loads)
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final local = Provider.of<LocalData>(
                            context,
                            listen: false,
                          );
                          local.loadIssueData(issue.id);
                        });

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(color: Colors.grey[350]),
                            CircularProgressIndicator(),
                          ],
                        );
                      },
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      // color: Colors.black.withValues(alpha: 0.7),
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
                    height: constraints.maxHeight * 0.4,
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
                                        issue.title ?? 'Untitled',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineMedium,
                                      ),
                                    ),
                                    SizedBox(
                                      width: constraints1.maxWidth * 0.2,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          // Upvote button
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
                                                if (issue.upvoteCount != null)
                                                  SizedBox(height: 2),
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
                                          ),
                                          SizedBox(height: 15),
                                          // Comments
                                          GestureDetector(
                                            onTap: () {
                                              debugPrint("Open comments.");
                                            },
                                            child: Column(
                                              children: [
                                                Icon(Icons.comment),
                                                if (issue.commentCount != null)
                                                  SizedBox(height: 2),
                                                if (issue.commentCount != null)
                                                  Text(
                                                    formatCompact(
                                                      issue.commentCount!,
                                                    ),
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
                                SizedBox(height: 10),
                                Container(
                                  alignment: Alignment.topLeft,
                                  height: constraints1.maxHeight * 0.1,
                                  child: Text(
                                    issue.description ?? '',
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
