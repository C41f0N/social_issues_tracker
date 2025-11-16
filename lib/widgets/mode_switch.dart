/*
  Mode Switcher
  ---

  A switch to toggle between the Attendance and Competitions mode.
*/

import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as math;
import 'package:flutter/material.dart';

class ModeSwitch extends StatefulWidget {
  const ModeSwitch({
    super.key,
    required this.width,
    required this.thumbColor,
    required this.mode,
    required this.onChanged,
    required this.mode1Name,
    required this.mode2Name,
    required this.backgroundColor,
    required this.surfaceColor,
  });

  final double width;
  final Color thumbColor;
  // true for Attendance, false for Competitions
  final bool mode;
  final Function(bool) onChanged;
  final String mode1Name;
  final String mode2Name;
  final Color backgroundColor;
  final Color surfaceColor;

  @override
  State<ModeSwitch> createState() => _ModeSwitchState();
}

class _ModeSwitchState extends State<ModeSwitch> {
  Offset position = Offset(0, 0);
  Offset initialPosition = Offset(0, 0);
  double thumbRatio = 0.8;

  double drag = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            widget.onChanged(!widget.mode);
          },

          onHorizontalDragStart: (DragStartDetails details) {
            initialPosition = details.localPosition;
          },

          onHorizontalDragUpdate: (DragUpdateDetails details) {
            setState(() {
              drag = details.localPosition.dx - initialPosition.dx;

              if (widget.mode && drag < 0) {
                drag = 0;
              } else if (!widget.mode && drag > 0) {
                drag = 0;
              } else {
                if (drag > widget.width * (1 - thumbRatio)) {
                  drag = widget.width * (1 - thumbRatio);
                } else if (drag < -widget.width * (1 - thumbRatio)) {
                  drag = -widget.width * (1 - thumbRatio);
                }
              }
            });
          },

          onHorizontalDragEnd: (DragEndDetails details) {
            if (widget.mode && drag < 0) {
              setState(() {
                drag = 0;
              });
            } else if (!widget.mode && drag > 0) {
              setState(() {
                drag = 0;
              });
            } else if (drag.abs() > widget.width * (1 - thumbRatio) / 2) {
              setState(() {
                drag = 0;
              });
              widget.onChanged(!widget.mode);
            } else {
              setState(() {
                drag = 0;
              });
            }
          },

          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(90),
                ),
                width: widget.width,
                height: 30,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.width * (1 - thumbRatio) * 0.1,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastEaseInToSlowEaseOut,
                transform: Matrix4.translation(
                  math.Vector3(
                    widget.mode
                        ? -widget.width * (1 - thumbRatio) / 2 + drag.abs()
                        : widget.width * (1 - thumbRatio) / 2 + -drag.abs(),
                    0,
                    0,
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentGeometry.topLeft,
                    end: AlignmentGeometry.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(90),
                ),
                alignment: Alignment.center,
                width: widget.width * thumbRatio,
                height: 30,
                child: Text(
                  widget.mode ? widget.mode1Name : widget.mode2Name,
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
