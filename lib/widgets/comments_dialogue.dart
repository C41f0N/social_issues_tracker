import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/comment.dart';
import 'package:social_issues_tracker/data/models/user.dart';

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
    final comments = local.getCommentsForIssue(widget.issueId);

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
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (ctx, i) {
                          final Comment c = comments[i];
                          final user = local.storedUsers.firstWhere(
                            (u) => u.id == c.postedBy,
                            orElse: () => User(id: 'unknown', name: 'User'),
                          );
                          final authorName = user.name ?? 'User';

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(radius: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authorName,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.content,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 10),
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
