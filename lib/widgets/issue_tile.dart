// Wall item tile that renders either an Issue or a Group depending on `isGroup`.

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/constants.dart';
import 'package:social_issues_tracker/pages/issue_view_page.dart';
import 'package:social_issues_tracker/pages/group_view_page.dart' hide Container;
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/issue.dart';
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

    final title = isGroup ? (group?.title ?? 'Untitled') : (issue?.title ?? 'Untitled');
    final upvoteCount = isGroup ? group?.upvoteCount : issue?.upvoteCount;
    final commentCount = isGroup ? group?.commentCount : issue?.commentCount;
    final description = isGroup ? group?.description : issue?.description;

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
                    child: Builder(
                      builder: (context) {
                        final loaded = isGroup ? (group?.loaded ?? false) : (issue?.loaded ?? false);
                        final imageData = isGroup ? group?.imageData : issue?.imageData;
                        if (loaded && imageData != null) {
                          return Image.memory(
                            imageData,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[350]),
                          );
                        }

                        final isLoading = isGroup
                            ? local.isLoading(widget.itemId, isGroup: true)
                            : local.isLoading(widget.itemId);

                        if (!isLoading) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final local = Provider.of<LocalData>(context, listen: false);
                            if (isGroup) {
                              local.loadGroupData(widget.itemId);
                            } else {
                              local.loadIssueData(widget.itemId);
                            }
                          });
                        }

                        if (isLoading) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(color: Colors.grey[350]),
                              const CircularProgressIndicator(),
                            ],
                          );
                        }

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(color: Colors.grey[350]),
                            ElevatedButton.icon(
                              onPressed: () {
                                final local = Provider.of<LocalData>(context, listen: false);
                                if (isGroup) {
                                  local.reloadGroupData(widget.itemId);
                                } else {
                                  local.reloadIssueData(widget.itemId);
                                }
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        );
                      },
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
                    height: constraints.maxHeight * 0.4,
                    child: Container(
                      alignment: AlignmentGeometry.bottomCenter,
                      child: LayoutBuilder(
                        builder: (context, constraints1) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: constraints1.maxWidth * 0.05),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      alignment: Alignment.bottomLeft,
                                      width: constraints1.maxWidth * 0.7,
                                      child: Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.headlineMedium,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                upvoted = !upvoted;
                                              });
                                            },
                                            child: Column(
                                              children: [
                                                Icon(upvoted ? upvoteIconFilled : upvoteIconOutlined),
                                                if (upvoteCount != null) SizedBox(height: 2),
                                                if (upvoteCount != null)
                                                  Text(
                                                    formatCompact(upvoteCount!),
                                                    style: Theme.of(context).textTheme.labelSmall,
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
                                                builder: (_) => CommentsDialogue(issueId: widget.itemId),
                                              );
                                            },
                                            child: Column(
                                              children: [
                                                Icon(Icons.comment),
                                                if (commentCount != null) SizedBox(height: 2),
                                                if (commentCount != null)
                                                  Text(
                                                    formatCompact(commentCount!),
                                                    style: Theme.of(context).textTheme.labelSmall,
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
                                    description ?? '',
                                    style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey[600]),
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

// removed unused dart:math import

// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:provider/provider.dart';
// import 'package:social_issues_tracker/constants.dart';
// import 'package:social_issues_tracker/data/models/comment.dart';
// import 'package:social_issues_tracker/pages/issue_view_page.dart';
// import 'package:social_issues_tracker/pages/group_view_page.dart';
// import 'package:social_issues_tracker/data/local_data.dart';
// import 'package:social_issues_tracker/data/models/issue.dart';
// import 'package:social_issues_tracker/data/models/group.dart';
// import 'package:social_issues_tracker/utils.dart';
// import 'package:social_issues_tracker/widgets/comments_dialogue.dart';

// class IssueTile extends StatefulWidget {
//   const IssueTile({
//     super.key,
//     this.width,
//     required this.height,
//     required this.itemId,
//     this.isGroup = false,
//   });

//   @override
//   State<IssueTile> createState() => _IssueTileState();

//   final double height;
//   final double? width;
//   final String itemId;
//   final bool isGroup;
// }

// class _IssueTileState extends State<IssueTile> {
//   bool upvoted = false;

//   @override
//   Widget build(BuildContext context) {
//     final local = Provider.of<LocalData>(context);
//     final isGroup = widget.isGroup;
//     final Issue? issue = isGroup ? null : local.getIssueById(widget.itemId);
//     final Group? group = isGroup ? local.getGroupById(widget.itemId) : null;

//     final title = isGroup ? (group?.title ?? 'Untitled') : (issue?.title ?? 'Untitled');
//     final upvoteCount = isGroup ? group?.upvoteCount : issue?.upvoteCount;
//     final commentCount = isGroup ? group?.commentCount : issue?.commentCount;
//     final description = isGroup ? group?.description : issue?.description;

//     return Material(
//       color: Theme.of(context).colorScheme.surface,
//       child: GestureDetector(
//         onTap: () {
//           context.pushTransition(
//             type: PageTransitionType.rightToLeft,
//             child: isGroup
//                 ? GroupViewPage(groupId: widget.itemId)
//                 : IssueViewPage(issueId: widget.itemId),
//           );
//         },
//         child: Container(
//           width: widget.width,
//           height: widget.height,
//           decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               return Stack(
//                 alignment: AlignmentGeometry.bottomCenter,
//                 children: [
//                   // Image area
//                   Container(
//                     color: Colors.grey[400],
//                     height: constraints.maxHeight * 1,
//                     child: Builder(
//                       builder: (context) {
//                         final loaded = isGroup ? (group?.loaded ?? false) : (issue?.loaded ?? false);
//                         final imageData = isGroup ? group?.imageData : issue?.imageData;
//                         if (loaded && imageData != null) {
//                           return Image.memory(
//                             imageData,
//                             fit: BoxFit.cover,
//                             width: double.infinity,
//                             height: double.infinity,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Container(color: Colors.grey[350]);
//                             },
//                           );
//                         }

//                         final isLoading = isGroup
//                             ? local.isLoading(widget.itemId, isGroup: true)
//                             : local.isLoading(widget.itemId);

//                         if (!isLoading) {
//                           WidgetsBinding.instance.addPostFrameCallback((_) {
//                             final local = Provider.of<LocalData>(context, listen: false);
//                             if (isGroup) {
//                               local.loadGroupData(widget.itemId);
//                             } else {
//                               local.loadIssueData(widget.itemId);
//                             }
//                           });
//                         }

//                         if (isLoading) {
//                           return Stack(
//                             alignment: Alignment.center,
//                             children: [
//                               Container(color: Colors.grey[350]),
//                               const CircularProgressIndicator(),
//                             ],
//                           );
//                         }

//                         return Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             Container(color: Colors.grey[350]),
//                             ElevatedButton.icon(
//                               onPressed: () {
//                                 final local = Provider.of<LocalData>(context, listen: false);
//                                 if (isGroup) {
//                                   local.reloadGroupData(widget.itemId);
//                                 } else {
//                                   local.reloadIssueData(widget.itemId);
//                                 }
//                               },
//                               icon: const Icon(Icons.refresh),
//                               label: const Text('Retry'),
//                             ),
//                           ],
//                         );
//                       },
//                     ),
//                   ),

//                   // Gradient overlay with title / actions
//                   Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           Colors.black.withValues(alpha: 0.0),
//                           Colors.black.withValues(alpha: 0.7),
//                           Colors.black.withValues(alpha: 1),
//                         ],
//                         stops: [0, 0.4, 1],
//                         begin: AlignmentGeometry.topCenter,
//                         end: AlignmentGeometry.bottomCenter,
//                       ),
//                     ),
//                     height: constraints.maxHeight * 0.4,
//                     child: Container(
//                       alignment: AlignmentGeometry.bottomCenter,
//                       child: LayoutBuilder(
//                         builder: (context, constraints1) {
//                           return Padding(
//                             padding: EdgeInsets.symmetric(horizontal: constraints1.maxWidth * 0.05),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 Row(
//                                   crossAxisAlignment: CrossAxisAlignment.end,
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Container(
//                                       alignment: Alignment.bottomLeft,
//                                       width: constraints1.maxWidth * 0.7,
//                                       child: Text(
//                                         title,
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: Theme.of(context).textTheme.headlineMedium,
//                                       ),
//                                     ),
//                                     SizedBox(
//                                       width: 40,
//                                       child: Column(
//                                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                         crossAxisAlignment: CrossAxisAlignment.center,
//                                         children: [
//                                           GestureDetector(
//                                             onTap: () {
//                                               setState(() {
//                                                 upvoted = !upvoted;
//                                               });
//                                             },
//                                             child: Column(
//                                               children: [
//                                                 Icon(upvoted ? upvoteIconFilled : upvoteIconOutlined),
//                                                 if (upvoteCount != null) SizedBox(height: 2),
//                                                 if (upvoteCount != null)
//                                                   Text(
//                                                     formatCompact(upvoteCount!),
//                                                     style: Theme.of(context).textTheme.labelSmall,
//                                                   ),
//                                               ],
//                                             ),
//                                           ),
//                                           SizedBox(height: 15),
//                                           GestureDetector(
//                                             onTap: () {
//                                               debugPrint('Open comments.');
//                                               showDialog(
//                                                 context: context,
//                                                 builder: (_) => CommentsDialogue(issueId: widget.itemId),
//                                               );
//                                             },
//                                             child: Column(
//                                               children: [
//                                                 Icon(Icons.comment),
//                                                 if (commentCount != null) SizedBox(height: 2),
//                                                 if (commentCount != null)
//                                                   Text(
//                                                     formatCompact(commentCount!),
//                                                     style: Theme.of(context).textTheme.labelSmall,
//                                                   ),
//                                               ],
//                                             ),
//                                           ),
//                                           SizedBox(height: 70),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 10),
//                                 Container(
//                                   alignment: Alignment.topLeft,
//                                   height: constraints1.maxHeight * 0.1,
//                                   child: Text(
//                                     description ?? '',
//                                     style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey[600]),
//                                     textAlign: TextAlign.left,
//                                     overflow: TextOverflow.ellipsis,
//                                     maxLines: 2,
//                                   ),
//                                 ),
//                                 SizedBox(height: 80),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
// // removed unused dart:math import

// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:provider/provider.dart';
// import 'package:social_issues_tracker/constants.dart';
// import 'package:social_issues_tracker/data/models/comment.dart';
// import 'package:social_issues_tracker/pages/issue_view_page.dart';
// import 'package:social_issues_tracker/pages/group_view_page.dart';
// import 'package:social_issues_tracker/data/local_data.dart';
// import 'package:social_issues_tracker/data/models/issue.dart';
// import 'package:social_issues_tracker/utils.dart';
// import 'package:social_issues_tracker/widgets/comments_dialogue.dart';

// class IssueTile extends StatefulWidget {
//   const IssueTile({
//     super.key,
//     this.width,
//     required this.height,
//     required this.itemId,
//     this.isGroup = false,
//   });

//   @override
//   State<IssueTile> createState() => _IssueTileState();

//   final double height;
//   final double? width;
//   final String itemId;
//   final bool isGroup;
// }

// class _IssueTileState extends State<IssueTile> {
//   bool upvoted = false;

//   @override
//   Widget build(BuildContext context) {
//     final local = Provider.of<LocalData>(context);
//     final isGroup = widget.isGroup;
//     final issue = isGroup
//         ? null
//         : local.getIssueById(widget.itemId);
//     final group = isGroup ? local.getGroupById(widget.itemId) : null;

//     return Material(
//       color: Theme.of(context).colorScheme.surface,
//       child: GestureDetector(
//         onTap: () {
//           context.pushTransition(
//             type: PageTransitionType.rightToLeft,
//             child: isGroup
//                 ? GroupViewPage(groupId: widget.itemId)
//                 : IssueViewPage(issueId: widget.itemId),
//           );
//         },
//         child: Container(
//           width: widget.width,
//           height: widget.height,
//           decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               return Stack(
//                 alignment: AlignmentGeometry.bottomCenter,
//                 final isGroup = widget.isGroup;
//                 final issue = isGroup ? null : local.getIssueById(widget.itemId);
//                 final group = isGroup ? local.getGroupById(widget.itemId) : null;
//                       builder: (context) {
//                 final title = isGroup ? (group?.title ?? 'Untitled') : (issue?.title ?? 'Untitled');
//                 final upvoteCount = isGroup ? group?.upvoteCount : issue?.upvoteCount;
//                 final commentCount = isGroup ? group?.commentCount : issue?.commentCount;
//                 final description = isGroup ? group?.description : issue?.description;
//                         // If image data already loaded, show it; otherwise show placeholder
//                         final loaded = isGroup ? group!.loaded : issue!.loaded;
//                         final imageData = isGroup ? group!.imageData : issue!.imageData;
//                         if (loaded && imageData != null) {
//                           return Image.memory(
//                             imageData,
//                             fit: BoxFit.cover,
//                             width: double.infinity,
//                             height: double.infinity,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Container(color: Colors.grey[350]);
//                             },
//                           );
//                         }

//                         final isLoading = isGroup
//                             ? local.isLoading(widget.itemId, isGroup: true)
//                             : local.isLoading(widget.itemId);

//                         // Trigger load after frame if not already loading (LocalData guards duplicates)
//                         if (!isLoading) {
//                           WidgetsBinding.instance.addPostFrameCallback((_) {
//                             final local = Provider.of<LocalData>(
//                               context,
//                               listen: false,
//                             );
//                             if (isGroup) {
//                               local.loadGroupData(widget.itemId);
//                             } else {
//                               local.loadIssueData(widget.itemId);
//                             }
//                           });
//                         }

//                         if (isLoading) {
//                           return Stack(
//                             alignment: Alignment.center,
//                             children: [
//                               Container(color: Colors.grey[350]),
//                               const CircularProgressIndicator(),
//                             ],
//                           );
//                         }

//                         // Not loading and not loaded -> show placeholder + retry
//                         return Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             Container(color: Colors.grey[350]),
//                             ElevatedButton.icon(
//                               onPressed: () {
//                                 final local = Provider.of<LocalData>(
//                                   context,
//                                   listen: false,
//                                 );
//                                 if (isGroup) {
//                                   local.reloadGroupData(widget.itemId);
//                                 } else {
//                                   local.reloadIssueData(widget.itemId);
//                                 }
//                               },
//                               icon: const Icon(Icons.refresh),
//                               label: const Text('Retry'),
//                             ),
//                           ],
//                         );
//                       },
//                     ),
//                   ),

//                   Container(
//                     decoration: BoxDecoration(
//                       // color: Colors.black.withValues(alpha: 0.7),
//                       gradient: LinearGradient(
//                         colors: [
//                           Colors.black.withValues(alpha: 0.0),
//                           Colors.black.withValues(alpha: 0.7),
//                           Colors.black.withValues(alpha: 1),
//                         ],
//                         stops: [0, 0.4, 1],
//                         begin: AlignmentGeometry.topCenter,
//                         end: AlignmentGeometry.bottomCenter,
//                       ),
//                     ),
//                     height: constraints.maxHeight * 0.4,
//                     child: Container(
//                       alignment: AlignmentGeometry.bottomCenter,
//                       child: LayoutBuilder(
//                         builder: (context, constraints1) {
//                           return Padding(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: constraints1.maxWidth * 0.05,
//                             ),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 Row(
//                                   crossAxisAlignment: CrossAxisAlignment.end,
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Container(
//                                       alignment: Alignment.bottomLeft,
//                                       width: constraints1.maxWidth * 0.7,
//                                       child: Text(
//                                         issue.title ?? 'Untitled',
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: Theme.of(
//                                           context,
//                                         ).textTheme.headlineMedium,
//                                       ),
//                                     ),
//                                     SizedBox(
//                                       width: 40,
//                                       child: Column(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceEvenly,
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.center,
//                                         children: [
//                                           // Upvote button
//                                           GestureDetector(
//                                             onTap: () {
//                                               setState(() {
//                                                 upvoted = !upvoted;
//                                               });
//                                             },
//                                             child: Column(
//                                               children: [
//                                                     title,
//                                                   upvoted
//                                                       ? upvoteIconFilled
//                                                       : upvoteIconOutlined,
//                                                 ),
//                                                 if (issue.upvoteCount != null)
//                                                   SizedBox(height: 2),
//                                                 if (issue.upvoteCount != null)
//                                                   Text(
//                                                     formatCompact(
//                                                       issue.upvoteCount!,
//                                                     ),
//                                                     style: Theme.of(
//                                                       context,
//                                                     ).textTheme.labelSmall,
//                                                   ),
//                                               ],
//                                             ),
//                                           ),
//                                           SizedBox(height: 15),
//                                           // Comments
//                                           GestureDetector(
//                                             onTap: () {
//                                               debugPrint("Open comments.");
//                                               showDialog(
//                                                 context: context,
//                                                 builder: (_) =>
//                                                     CommentsDialogue(
//                                                       issueId: issue.id,
//                                                     ),
//                                               );
//                                             },
//                                             child: Column(
//                                               children: [
//                                                 Icon(Icons.comment),
//                                                 if (issue.commentCount != null)
//                                                   SizedBox(height: 2),
//                                                 if (issue.commentCount != null)
//                                                   Text(
//                                                     formatCompact(
//                                                       issue.commentCount!,
//                                                     ),
//                                                     style: Theme.of(
//                                                       context,
//                                                     ).textTheme.labelSmall,
//                                                   ),
//                                               ],
//                                             ),
//                                           ),
//                                           SizedBox(height: 70),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 10),
//                                 Container(
//                                   alignment: Alignment.topLeft,
//                                   height: constraints1.maxHeight * 0.1,
//                                   child: Text(
//                                     issue.description ?? '',
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall!
//                                         .copyWith(color: Colors.grey[600]),
//                                     textAlign: TextAlign.left,
//                                     overflow: TextOverflow.ellipsis,
//                                     maxLines: 2,
//                                   ),
//                                 ),
//                                 SizedBox(height: 80),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//                                                 description ?? '',
// }
