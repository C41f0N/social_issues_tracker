import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:social_issues_tracker/widgets/issue_tile.dart';
import 'package:social_issues_tracker/widgets/mode_switch.dart';
// import 'package:social_issues_tracker/widgets/mode_switch.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool optionsOpened = false;

  @override
  Widget build(BuildContext context) {
    int numIssues = 10;

    Duration animationDuration1 = const Duration(milliseconds: 100);
    Duration animationDuration2 = const Duration(milliseconds: 250);
    Curve animationCurve = Curves.fastEaseInToSlowEaseOut;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          alignment: Alignment.center,
          children: [
            // The wall
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: ListView.builder(
                itemCount: numIssues,
                itemBuilder: (context, i) => Padding(
                  padding: i == 0
                      ? EdgeInsets.fromLTRB(
                          MediaQuery.of(context).size.width * 0.1,
                          MediaQuery.of(context).size.height * 0.15,
                          MediaQuery.of(context).size.width * 0.1,
                          20,
                        )
                      : i == numIssues - 1
                      ? EdgeInsets.fromLTRB(
                          MediaQuery.of(context).size.width * 0.1,
                          20,
                          MediaQuery.of(context).size.width * 0.1,
                          MediaQuery.of(context).size.height * 0.1,
                        )
                      : EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.1,
                          vertical: 20,
                        ),
                  child: IssueTile(),
                ),
              ),
            ),

            // Profile button
            Positioned(
              top: MediaQuery.of(context).size.height * 0.025,
              right: MediaQuery.of(context).size.height * 0.025,
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      spreadRadius: 10,
                      blurRadius: 20,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(90),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Mode Switcher
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.025,
              child: ModeSwitch(
                width: 300,
                thumbColor: Theme.of(context).colorScheme.primary,
                mode: true,
                onChanged: (x) {},
                mode1Name: "Highlighted",
                mode2Name: "Recent",
                backgroundColor: Theme.of(context).colorScheme.secondary,
                surfaceColor: Theme.of(context).colorScheme.surface,
              ),
            ),

            // Options
            IgnorePointer(
              ignoring: !optionsOpened,
              child: AnimatedOpacity(
                duration: animationDuration2,
                curve: animationCurve,
                opacity: optionsOpened ? 1 : 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      optionsOpened = false;
                    });
                  },
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),

            // Options button
            Positioned(
              top: MediaQuery.of(context).size.height * 0.025,
              left: MediaQuery.of(context).size.height * 0.025,
              child: SizedBox(
                height: 50,
                width: 50,
                child: Center(
                  child: SizedBox(
                    height: 40,
                    width: 50,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTap: () => setState(() {
                            optionsOpened = !optionsOpened;
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  spreadRadius: 10,
                                  blurRadius: 20,
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                            child: Builder(
                              builder: (context) {
                                Widget optionsBar = AnimatedContainer(
                                  duration: animationDuration1,
                                  curve: animationCurve,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(90),
                                    color: optionsOpened
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                  height: constraints.maxHeight / 5,
                                );

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedSlide(
                                      offset: !optionsOpened
                                          ? Offset(0, 2)
                                          : Offset(0, 0),
                                      duration: animationDuration1,
                                      curve: animationCurve,

                                      child: AnimatedRotation(
                                        turns: optionsOpened ? 0.125 : 0,
                                        duration: animationDuration1,
                                        curve: animationCurve,
                                        child: optionsBar,
                                      ),
                                    ),
                                    AnimatedSlide(
                                      offset: !optionsOpened
                                          ? Offset(0, 0)
                                          : Offset(0, 0),
                                      duration: animationDuration1,
                                      curve: animationCurve,
                                      child: AnimatedRotation(
                                        turns: optionsOpened ? 0.125 : 0,
                                        duration: animationDuration1,
                                        curve: animationCurve,
                                        child: optionsBar,
                                      ),
                                    ),
                                    AnimatedSlide(
                                      duration: animationDuration1,
                                      curve: animationCurve,
                                      offset: !optionsOpened
                                          ? Offset(0, -2)
                                          : Offset(0, 0),
                                      child: AnimatedRotation(
                                        turns: optionsOpened ? -0.125 : 0,
                                        duration: animationDuration1,
                                        curve: animationCurve,
                                        child: optionsBar,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
