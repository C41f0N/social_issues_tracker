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
  double thumbRatio = 0.75;

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
                height: 50,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.width * (1 - thumbRatio) * 1 / 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Stack(
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: widget.surfaceColor,
                          ),
                          Transform.translate(
                            offset: Offset(10, 0),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: widget.surfaceColor,
                            ),
                          ),
                        ],
                      ),
                      Transform.rotate(
                        angle: pi,
                        child: Stack(
                          children: [
                            Icon(
                              Icons.arrow_back_ios,
                              color: widget.surfaceColor,
                            ),
                            Transform.translate(
                              offset: Offset(10, 0),
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: widget.surfaceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  color: widget.thumbColor,
                  borderRadius: BorderRadius.circular(90),
                ),
                alignment: Alignment.center,
                width: widget.width * thumbRatio,
                height: 50,
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
