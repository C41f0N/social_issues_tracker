import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/pages/issue_edit_page.dart';
import 'package:social_issues_tracker/pages/profile_page.dart';
import 'package:social_issues_tracker/pages/requests_page.dart';
import 'package:social_issues_tracker/pages/group_edit_page.dart';
import 'package:social_issues_tracker/pages/search_page.dart';
import 'package:social_issues_tracker/utils/custom_reel_physics.dart';
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
  final PageController _pageController = PageController();
  bool wallMode = true; // True is highlights, false is recents
  final int _preloadCount = 3;

  @override
  void initState() {
    super.initState();
    // Fetch recent feed on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localData = Provider.of<LocalData>(context, listen: false);
      localData.fetchRecentFeed();
    });
  }

  // Preload issues around the current index: n before and n after.
  void _preloadAroundIndex(LocalData localData, int index) {
    final len = localData.feedItems.length;
    if (len == 0) return; // Safety check for empty feed
    final start = (index - _preloadCount).clamp(0, len - 1);
    final end = (index + _preloadCount).clamp(0, len - 1);

    for (int i = start; i <= end; i++) {
      final ref = localData.feedItems[i];
      if (ref.isGroup) {
        final grp = localData.getGroupById(ref.id);
        if (grp.loaded) continue;
        if (localData.isLoading(ref.id, isGroup: true)) continue;
        localData.loadGroupData(ref.id);
      } else {
        final issue = localData.getIssueById(ref.id);
        // Check if issue is fully loaded, if not fetch it
        if (!issue.fullyLoaded) {
          localData.fetchIssueById(ref.id);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Duration animationDuration1 = const Duration(milliseconds: 100);
    Duration animationDuration2 = const Duration(milliseconds: 250);
    Curve animationCurve = Curves.fastEaseInToSlowEaseOut;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          alignment: Alignment.center,
          children: [
            // Reels-style vertical pager
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: Consumer<LocalData>(
                builder: (context, localData, child) {
                  print(localData.feedItems.map((x) => x.isGroup));

                  // Preload around the current page on first build.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final current = _pageController.hasClients
                        ? _pageController.page?.round() ?? 0
                        : 0;
                    _preloadAroundIndex(localData, current);
                  });

                  return PageView.builder(
                    physics: const CustomPageViewScrollPhysics(),
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    pageSnapping: true,
                    itemCount: localData.feedItems.length,
                    onPageChanged: (index) {
                      // Preload _preloadCount before and after the current index.
                      _preloadAroundIndex(localData, index);
                    },
                    itemBuilder: (context, i) {
                      final size = MediaQuery.of(context).size;
                      final ref = localData.feedItems[i];
                      return SizedBox(
                        height: size.height,
                        width: size.width,
                        child: IssueTile(
                          height: size.height,
                          itemId: ref.id,
                          isGroup: ref.isGroup,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Shadow at top
            Positioned(
              top: 0,
              child: Container(
                height: 70,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                    stops: [0, 1],
                    begin: AlignmentGeometry.topCenter,
                    end: AlignmentGeometry.bottomCenter,
                  ),
                ),
              ),
            ),

            // Shadow at bottom
            Positioned(
              bottom: 0,
              child: Container(
                height: 60,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: [0, 1],
                    begin: AlignmentGeometry.topCenter,
                    end: AlignmentGeometry.bottomCenter,
                  ),
                ),
              ),
            ),

            // Profile button
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.025,
              left: MediaQuery.of(context).size.height * 0.025,
              child: ProfileButton(),
            ),

            // Mode Switcher
            Positioned(
              top: MediaQuery.of(context).size.height * 0.025,
              child: ModeSwitch(
                width: 230,
                thumbColor: Theme.of(context).colorScheme.primary,
                mode: wallMode,
                onChanged: (x) {
                  setState(() {
                    wallMode = !wallMode;
                  });
                },
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
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Add Issue
                            OptionButton(
                              icon: Icon(Icons.add),
                              label: Text("New Issue"),
                              onTap: () {
                                debugPrint("HERE");
                                setState(() {
                                  optionsOpened = false;
                                });
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const IssueEditPage(
                                      mode: IssueEditMode.create,
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 10),

                            // Add Group
                            OptionButton(
                              icon: Icon(Icons.add),
                              label: Text("New Group"),
                              onTap: () {
                                setState(() {
                                  optionsOpened = false;
                                });
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const GroupEditPage(
                                      mode: GroupEditMode.create,
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 10),

                            // Search
                            OptionButton(
                              icon: Icon(Icons.search),
                              label: Text("Search"),
                              onTap: () {
                                setState(() {
                                  optionsOpened = false;
                                });
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SearchPage(),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 10),

                            // Requests
                            OptionButton(
                              icon: Icon(Icons.inbox_outlined),
                              label: Text("Requests"),
                              onTap: () {
                                setState(() {
                                  optionsOpened = false;
                                });
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RequestsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Options button
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.025,
              right: MediaQuery.of(context).size.height * 0.025,
              child: SizedBox(
                height: 50,
                width: 50,
                child: Center(
                  child: SizedBox(
                    height: 30,
                    width: 40,
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
                                  blurRadius: 50,
                                  color: Colors.black.withValues(alpha: 0.2),
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

                                    // color: optionsOpened
                                    //     ? Theme.of(context).colorScheme.primary
                                    //     : Theme.of(context).colorScheme.primary,
                                    gradient: LinearGradient(
                                      begin: AlignmentGeometry.topLeft,
                                      end: AlignmentGeometry.bottomRight,
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.tertiary,
                                      ],
                                    ),
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

class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    this.onTap,
    required this.label,
    required this.icon,
  });

  final void Function()? onTap;
  final Widget label, icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [icon, label, SizedBox()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigator.of(
        //   context,
        // ).push(MaterialPageRoute(builder: (context) => ProfilePage()));
        context.pushTransition(
          type: PageTransitionType.rightToLeft,
          child: ProfilePage(),
        );
      },
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              spreadRadius: 10,
              blurRadius: 20,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ],
          borderRadius: BorderRadius.circular(90),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary,
            ],
          ),
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
