import 'package:flutter/material.dart';

class WithCustomHeader extends StatefulWidget {
  const WithCustomHeader({super.key, required this.child});

  final Widget child;

  @override
  State<WithCustomHeader> createState() => _WithCustomHeaderState();
}

class _WithCustomHeaderState extends State<WithCustomHeader> {
  ScrollController scrollController = ScrollController();

  bool headerOpen = false;
  double _lastOffset = 0.0;
  static const double _directionThreshold = 2.0; // pixels

  @override
  void initState() {
    scrollController.addListener(() {
      final current = scrollController.offset;
      final delta = current - _lastOffset;

      if (delta < _directionThreshold) {
        // User swiped up -> show header
        if (!headerOpen) {
          headerOpen = true;
        }
      } else if (delta > -_directionThreshold) {
        // User swiped down -> hide header
        if (headerOpen) {
          headerOpen = false;
        }
      }

      _lastOffset = current;
      setState(() {}); // still rebuild for opacity/background changes
    });

    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              controller: scrollController,
              child: widget.child,
            ),
          ),

          // Back Button
          AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: Offset(0, headerOpen ? 0 : -1),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(
                  alpha: (scrollController.hasClients
                      ? scrollController.offset /
                                    MediaQuery.of(context).size.height >
                                1
                            ? 1
                            : scrollController.offset /
                                  MediaQuery.of(context).size.height
                      : 1),
                ),
              ),
              height: 60,
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
