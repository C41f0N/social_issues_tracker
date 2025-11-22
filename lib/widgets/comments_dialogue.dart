import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/comment.dart';
import 'package:social_issues_tracker/data/models/user.dart';
import 'package:social_issues_tracker/widgets/comment_widget.dart';

class CommentsDialogue extends StatefulWidget {
  const CommentsDialogue({super.key, required this.issueId});

  final String issueId;

  @override
  State<CommentsDialogue> createState() => _CommentsDialogueState();
}

class _CommentsDialogueState extends State<CommentsDialogue> {
  @override
  Widget build(BuildContext context) {
    final local = Provider.of<LocalData>(context);
    final comments = local.getCommentsIdsForIssue(widget.issueId);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: comments.isEmpty
                    ? Center(child: Text('No comments yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (ctx, i) {
                          return CommentWidget(
                            commentId: comments[i],
                            padding: 0,
                          );
                        },
                        itemCount: comments.length,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Add a comment',
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isEmpty) return;
                          // Create a very small synthetic comment and add to local
                          final newComment = Comment(
                            id: 'c_${widget.issueId}_${DateTime.now().millisecondsSinceEpoch}',
                            issueId: widget.issueId,
                            postedBy: local.storedUsers.isNotEmpty
                                ? local.storedUsers.first.id
                                : 'user1',
                            content: text.trim(),
                          );
                          local.addComment(newComment);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        // Let the TextField's onSubmitted handle adding; focus change will submit in real UI.
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
