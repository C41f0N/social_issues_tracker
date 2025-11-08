import 'package:flutter/material.dart';
import 'package:social_issues_tracker/widgets/with_custom_header.dart';

class IssueViewPage extends StatefulWidget {
  const IssueViewPage({super.key});

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
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WithCustomHeader(
        child: Stack(
          children: [
            // Image
            Transform.translate(
              offset: Offset(
                0,
                scrollController.hasClients ? scrollController.offset * 0.5 : 0,
              ),
              child: Opacity(
                opacity:
                    1 -
                    (scrollController.hasClients
                        ? scrollController.offset /
                                      MediaQuery.of(context).size.height >
                                  1
                              ? 1
                              : scrollController.offset /
                                    MediaQuery.of(context).size.height
                        : 1),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Image.network(
                    "https://fastly.picsum.photos/id/191/400/300.jpg?hmac=hIxLgbrqDZEjX-aB2VBUKokyxQXbvjHvTJQgLIvQSo0",
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;

                      return Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ),

            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.4 - 20),
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
                                  Text(
                                    "LOL",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineLarge,
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

                              SizedBox(height: 30),

                              // Details
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    descriptionExpanded = !descriptionExpanded;
                                  });
                                },
                                child: Text(
                                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                                width: MediaQuery.of(context).size.width * 0.8,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          ...List.generate(
                                            2,
                                            (i) => Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                0,
                                                i == 0 ? 10 : 10,
                                                0,
                                                i == 3 - 1 ? 0 : 10,
                                              ),
                                              child: Container(
                                                width:
                                                    constraints.maxWidth * 0.9,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface
                                                      .withValues(alpha: 0.9),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    16.0,
                                                  ),
                                                  child: Column(
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
                                                          SizedBox(width: 6),
                                                          Transform.translate(
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                            child: Text(
                                                              "User",
                                                              style:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .textTheme
                                                                      .bodyLarge,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        "Lorem ipsum dolor sit amet lorem ipsum dolor sit amet lorem ipsum dolor sit amet lorem ipsum dolor sit amet lorem ipsum dolor sit amet lorem ipsum dolor sit amet lorem ipsum dolor sit amet ",
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.bodySmall,
                                                        overflow: TextOverflow
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
                                                        .withValues(alpha: 0.8),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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

                                                height:
                                                    constraints1.maxHeight *
                                                        0.5 -
                                                    spaceBetween * 0.5,
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Colors.red,
                                                ),
                                                width:
                                                    constraints.maxWidth * 0.45,
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
                CircleAvatar(radius: 50),
                SizedBox(height: 10),
                Text(
                  "User Name",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
