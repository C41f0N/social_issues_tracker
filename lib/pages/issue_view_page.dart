import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/constants.dart';
import 'package:social_issues_tracker/data/models/comment.dart';
import 'package:social_issues_tracker/data/models/user.dart';
import 'package:social_issues_tracker/utils.dart';
import 'package:social_issues_tracker/widgets/comments_dialogue.dart';
import 'package:social_issues_tracker/widgets/with_custom_header.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/data/models/issue.dart';

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
    // Trigger loading of the issue image as soon as the page is created.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final local = Provider.of<LocalData>(context, listen: false);
      local.loadIssueData(widget.issueId);
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
    final issue = local.storedIssues.firstWhere(
      (it) => it.id == widget.issueId,
      orElse: () => Issue(id: widget.issueId),
    );

    User? postedBy;

    if (issue != null && issue.postedBy != null) {
      postedBy = local.getUserById(issue.postedBy!);
    }

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
                child: Builder(
                  builder: (context) {
                    if (issue.loaded && issue.imageData != null) {
                      return Container(
                        child: Image.memory(
                          issue.imageData!,
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
                      local2.loadIssueData(issue.id);
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
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
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
                                          if (issue.upvoteCount != null)
                                            SizedBox(height: 5),
                                          if (issue.upvoteCount != null)
                                            Text(
                                              formatCompact(issue.upvoteCount!),
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
                                        builder: (_) =>
                                            CommentsDialogue(issueId: issue.id),
                                      );
                                    },
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        int commentCount = 2;

                                        List<Comment> comments = List.generate(
                                          issue.commentCount == null
                                              ? 0
                                              : commentCount >
                                                    issue.commentCount!
                                              ? issue.commentCount!
                                              : commentCount,
                                          (i) {
                                            return local.storedComments
                                                .firstWhere(
                                                  (x) =>
                                                      x.id ==
                                                      issue.commentIds[i],
                                                );
                                          },
                                        );

                                        // print(comments.map((x) => x.));

                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              ...List.generate(
                                                comments.length,
                                                (i) => Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                    0,
                                                    i == 0 ? 10 : 10,
                                                    0,
                                                    i == 3 - 1 ? 0 : 10,
                                                  ),
                                                  child: Container(
                                                    width:
                                                        constraints.maxWidth *
                                                        0.9,
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .surface
                                                          .withValues(
                                                            alpha: 0.9,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16.0,
                                                          ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .end,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              CircleAvatar(
                                                                radius: 12,
                                                              ),
                                                              SizedBox(
                                                                width: 6,
                                                              ),
                                                              Transform.translate(
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      2,
                                                                    ),
                                                                child: Text(
                                                                  comments[i].postedBy ==
                                                                          null
                                                                      ? ""
                                                                      : local.storedUsers
                                                                                .firstWhere(
                                                                                  (
                                                                                    x,
                                                                                  ) =>
                                                                                      x.id ==
                                                                                      comments[i].postedBy!,
                                                                                )
                                                                                .name ??
                                                                            "Unnamed",
                                                                  style: Theme.of(
                                                                    context,
                                                                  ).textTheme.bodyLarge,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            comments[i].content,
                                                            textAlign:
                                                                TextAlign.left,
                                                            style:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .bodySmall,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 2,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
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
                                  "Issue Files",
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
                  Text("Issue managed by"),
                  SizedBox(height: 10),
                  CircleAvatar(
                    radius: 50,
                    foregroundImage:
                        postedBy != null && postedBy.imageData != null
                        ? MemoryImage(postedBy.imageData!)
                        : null,
                  ),
                  SizedBox(height: 10),
                  Text(
                    postedBy != null ? postedBy.name ?? "user" : "user",
                    style: Theme.of(context).textTheme.headlineSmall,
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
