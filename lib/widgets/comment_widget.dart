import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/comment.dart';
import 'package:social_issues_tracker/data/models/user.dart';
import 'package:social_issues_tracker/pages/user_view_page.dart';
import 'package:social_issues_tracker/widgets/user_avatar.dart';
import 'package:timeago/timeago.dart';

class CommentWidget extends StatefulWidget {
  const CommentWidget({
    super.key,
    required this.commentId,
    this.width,
    this.padding = 16,
  });

  final String commentId;
  final double? width;
  final double padding;

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LocalData>(
      builder: (context, local, child) {
        Comment comment = local.getCommentById(widget.commentId);
        User? postedBy;
        if (comment.postedBy != null) {
          postedBy = local.getUserById(comment.postedBy!);
        }

        return Container(
          width: widget.width,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.pushTransition(
                          type: PageTransitionType.rightToLeft,
                          child: UserViewPage(userId: postedBy!.id),
                        );
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          UserAvatar(user: postedBy, radius: 12),
                          SizedBox(width: 6),
                          Transform.translate(
                            offset: const Offset(0, 2),
                            child: Text(
                              postedBy == null
                                  ? ""
                                  : postedBy.name ?? "Unnamed",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 5),
                    Transform.translate(
                      offset: const Offset(0, 2),

                      child: Container(
                        height: 5,
                        width: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(90),
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Transform.translate(
                      offset: const Offset(0, 2),
                      child: Text(
                        format(comment.postedAt),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  comment.content,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
