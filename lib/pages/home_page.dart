import 'package:flutter/material.dart';
import 'package:social_issues_tracker/widgets/issue_tile.dart';
import 'package:social_issues_tracker/widgets/mode_switch.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // The wall
          GestureDetector(
            onTap: () => debugPrint("Tap."),
            onPanEnd: (details) => debugPrint("Swipe"),
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.1,
                  vertical: 30,
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
                borderRadius: BorderRadius.circular(90),
                color: Theme.of(context).colorScheme.primary,
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
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:
                            List.generate(
                                  3,
                                  (i) => Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(90),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    height: constraints.maxHeight / 5,
                                  ),
                                )
                                as List<Widget>,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Mode Switcher
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.025,
            child: ModeSwitch(
              width: 300,
              thumbColor: Theme.of(context).colorScheme.primary,
              mode: false,
              onChanged: (x) {},
              mode1Name: "mode1Name",
              mode2Name: "mode2Name",
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceColor: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
