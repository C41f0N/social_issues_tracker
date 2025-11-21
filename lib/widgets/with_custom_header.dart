import 'package:flutter/material.dart';

class WithCustomHeader extends StatefulWidget {
  const WithCustomHeader({super.key, required this.child});

  final Widget child;

  @override
  State<WithCustomHeader> createState() => _WithCustomHeaderState();
}

class _WithCustomHeaderState extends State<WithCustomHeader> {
  bool headerOpen = true;
  double _lastOffset = 0.0;
  static const double _directionThreshold = 8.0; // pixels

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Listen to scroll notifications from descendant scrollables so
            // the header reacts to the actual inner scrolling (avoids
            // nested controller issues).
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                final current = notification.metrics.pixels;
                final delta = current - _lastOffset;

                if (delta > _directionThreshold) {
                  // User scrolled up (content moved up) -> show header
                  if (!headerOpen) headerOpen = true;
                } else if (delta < -_directionThreshold) {
                  // User scrolled down (content moved down) -> hide header
                  if (headerOpen) headerOpen = false;
                }

                _lastOffset = current;
                setState(() {});
                return false;
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: widget.child,
              ),
            ),

            // Back Button / Header
            AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              offset: Offset(0, headerOpen ? 0 : -1),
              child: Builder(
                builder: (context) {
                  final screenH = MediaQuery.of(context).size.height;
                  final alpha = (screenH > 0 ? (_lastOffset / screenH) : 0.0)
                      .clamp(0.0, 1.0);

                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: alpha),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
