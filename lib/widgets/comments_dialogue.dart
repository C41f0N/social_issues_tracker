import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/comment.dart';
import 'package:social_issues_tracker/data/models/user.dart';
import 'package:social_issues_tracker/widgets/comment_widget.dart';

class CommentsDialogue extends StatefulWidget {
  const CommentsDialogue({
    super.key,
    required this.issueId,
    this.isGroup = false,
  });

  final String issueId;
  final bool isGroup;

  @override
  State<CommentsDialogue> createState() => _CommentsDialogueState();
}

class _CommentsDialogueState extends State<CommentsDialogue> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitComment(LocalData local) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    if (widget.isGroup) {
      await local.addGroupComment(widget.issueId, text);
    } else {
      // Create a comment with temporary ID
      final newComment = Comment(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        issueId: widget.issueId,
        postedBy: '', // Will be filled by backend
        content: text,
      );
      await local.addComment(newComment);
    }
  }

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
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment',
                        ),
                        onSubmitted: (text) => _submitComment(local),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _submitComment(local),
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
