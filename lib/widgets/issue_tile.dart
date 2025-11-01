import 'package:flutter/material.dart';

class IssueTile extends StatefulWidget {
  const IssueTile({super.key, this.width, this.height = 300});

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
        child: InkWell(
          onTap: () {},
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.network(
                      "https://fastly.picsum.photos/id/191/400/300.jpg?hmac=hIxLgbrqDZEjX-aB2VBUKokyxQXbvjHvTJQgLIvQSo0",
                      fit: BoxFit.cover,
                      height: constraints.maxHeight * 0.6,
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
                            Container(
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
                                "FSdfasdfF SADFASDf SADFAdf ASDFASdf SADFASDF ASDFASDf",
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
