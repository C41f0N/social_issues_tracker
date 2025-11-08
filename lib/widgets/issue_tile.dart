import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:social_issues_tracker/pages/issue_view_page.dart';

class IssueTile extends StatefulWidget {
  const IssueTile({super.key, this.width, required this.height});

  @override
  State<IssueTile> createState() => _IssueTileState();

  final double height;
  final double? width;
}

class _IssueTileState extends State<IssueTile> {
  bool upvoted = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: GestureDetector(
        onTap: () {
          context.pushTransition(
            type: PageTransitionType.rightToLeft,
            child: IssueViewPage(),
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
                    child: Image.network(
                      "https://fastly.picsum.photos/id/191/400/300.jpg?hmac=hIxLgbrqDZEjX-aB2VBUKokyxQXbvjHvTJQgLIvQSo0",
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;

                        return Center(child: CircularProgressIndicator());
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
                    height: constraints.maxHeight * 0.2,
                    child: Container(
                      alignment: AlignmentGeometry.bottomCenter,
                      child: LayoutBuilder(
                        builder: (context, constraints1) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints1.maxWidth * 0.05,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      width: constraints1.maxWidth * 0.8,
                                      child: Text(
                                        "LOL",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineMedium,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          upvoted = !upvoted;
                                        });
                                      },
                                      icon: Icon(
                                        upvoted
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Container(
                                  alignment: Alignment.topLeft,
                                  height: constraints1.maxHeight * 0.3,
                                  child: Text(
                                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(color: Colors.grey[600]),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
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
