import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomPageViewScrollPhysics extends ScrollPhysics {
  const CustomPageViewScrollPhysics({ScrollPhysics? parent})
    : super(parent: parent);

  // Tunable constants.
  static const double velocityForNextPage =
      1300.0; // px/s threshold to force advancing page.
  static const double maxFlingPages =
      1.0; // never jump more than one extra page.
  static const Duration settleDuration = Duration(milliseconds: 260);
  static const Curve settleCurve = Curves.easeOutCubic;

  @override
  CustomPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageViewScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 1.0,
    stiffness: 650.0, // Lower stiffness for smoother ease-out.
    damping: 110.0, // Damping > 1 for critical-ish, prevents oscillation.
  );

  double _pageHeight(ScrollMetrics metrics) => metrics.viewportDimension;

  double _getTargetPixels(ScrollMetrics metrics, double velocity) {
    final pageExtent = _pageHeight(metrics);
    final currentPage = metrics.pixels / pageExtent;
    double targetPage;

    if (velocity.abs() > velocityForNextPage) {
      // Fling strong enough: move one page in direction (but clamp within range).
      targetPage = (velocity > 0
          ? currentPage + maxFlingPages
          : currentPage - maxFlingPages);
    } else {
      // Snap to closest page.
      targetPage = currentPage.roundToDouble();
    }

    // Clamp to bounds.
    final minPage = metrics.minScrollExtent / pageExtent;
    final maxPage = metrics.maxScrollExtent / pageExtent;
    targetPage = targetPage.clamp(minPage, maxPage);
    return targetPage * pageExtent;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics metrics,
    double velocity,
  ) {
    // If we're out of range let parent handle (e.g. overscroll glow).
    if ((velocity <= 0.0 && metrics.pixels <= metrics.minScrollExtent) ||
        (velocity >= 0.0 && metrics.pixels >= metrics.maxScrollExtent)) {
      return super.createBallisticSimulation(metrics, velocity);
    }

    final target = _getTargetPixels(metrics, velocity);
    if (target == metrics.pixels) {
      return null; // no movement needed.
    }

    // Use a custom time-based animation approximating settleDuration with curve.
    return _ReelSnapSimulation(
      start: metrics.pixels,
      end: target,
      curve: settleCurve,
      duration: settleDuration,
      pixelPerSecond: velocity,
    );
  }

  @override
  double get minFlingDistance => 5.0; // slight drag triggers snap.

  @override
  double carriedMomentum(double existingVelocity) => existingVelocity * 0.90;
}

/// A simple parametric simulation using a Curve over fixed duration.
class _ReelSnapSimulation extends Simulation {
  final double start;
  final double end;
  final Curve curve;
  final Duration duration;
  final double pixelPerSecond;
  final double _distance;

  _ReelSnapSimulation({
    required this.start,
    required this.end,
    required this.curve,
    required this.duration,
    required this.pixelPerSecond,
  }) : _distance = end - start;

  @override
  double x(double time) {
    final t = (time / duration.inMilliseconds).clamp(0.0, 1.0);
    final eased = curve.transform(t);
    return start + _distance * eased;
  }

  @override
  double dx(double time) {
    // Approximate derivative via finite difference of curve near t.
    final total = duration.inMilliseconds.toDouble();
    final t = (time / total).clamp(0.0, 1.0);
    if (t >= 1.0) return 0.0;
    const dt = 1 / 60.0; // frame step
    final eased = curve.transform(t);
    final easedNext = curve.transform(math.min(1.0, t + dt));
    final delta = easedNext - eased;
    return _distance * delta / dt / total; // velocity (px/s approx)
  }

  @override
  bool isDone(double time) => time >= duration.inMilliseconds;
}
