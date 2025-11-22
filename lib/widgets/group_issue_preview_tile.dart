import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/pages/issue_view_page.dart';

class GroupIssuePreviewTile extends StatefulWidget {
  const GroupIssuePreviewTile({super.key, required this.issueId, this.height = 100});

  final String issueId;
  final double height;

  @override
  State<GroupIssuePreviewTile> createState() => _GroupIssuePreviewTileState();
}

class _GroupIssuePreviewTileState extends State<GroupIssuePreviewTile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final local = Provider.of<LocalData>(context, listen: false);
      final issue = local.getIssueById(widget.issueId);
      if (!issue.loaded && !local.isLoading(issue.id)) {
        local.loadIssueData(issue.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = Provider.of<LocalData>(context);
    final issue = local.getIssueById(widget.issueId);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => IssueViewPage(issueId: issue.id),
          ),
        );
      },
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      issue.title ?? 'Untitled Issue',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      issue.description ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Builder(
                  builder: (context) {
                    if (issue.loaded && issue.imageData != null) {
                      return Image.memory(
                        issue.imageData!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[350]),
                      );
                    }
                    // Trigger load if needed (guard duplicates).
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!issue.loaded && !local.isLoading(issue.id)) {
                        local.loadIssueData(issue.id);
                      }
                    });
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(color: Colors.grey[300]),
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
