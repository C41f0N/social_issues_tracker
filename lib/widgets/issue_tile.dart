import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:social_issues_tracker/pages/issue_view_page.dart';

class IssueTile extends StatefulWidget {
  const IssueTile({super.key, this.width, this.height = 400});

  @override
  State<IssueTile> createState() => _IssueTileState();

  final double height;
  final double? width;
}

class _IssueTileState extends State<IssueTile> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: Theme.of(context).colorScheme.secondary,
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: Colors.grey[400],
                      height: constraints.maxHeight * 0.6,
                      child: Image.network(
                        "https://fastly.picsum.photos/id/191/400/300.jpg?hmac=hIxLgbrqDZEjX-aB2VBUKokyxQXbvjHvTJQgLIvQSo0",
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;

                          return Center(child: CircularProgressIndicator());
                        },
                      ),
                    ),
                    SizedBox(
                      height: constraints.maxHeight * 0.4,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.1,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: constraints.maxHeight * 0.1,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    alignment: Alignment.topLeft,
                                    width: constraints.maxWidth * 0.5,
                                    child: Text(
                                      "LOL",
                                      maxLines: 1,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineMedium,
                                    ),
                                  ),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: constraints.maxHeight * 0.05),
                            Container(
                              alignment: Alignment.topLeft,
                              height: constraints.maxHeight * 0.1,
                              child: Text(
                                "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(color: Colors.grey[600]),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
