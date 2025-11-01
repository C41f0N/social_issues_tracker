import 'package:flutter/material.dart';

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
            // child: SizedBox(child: Container(color: Colors.red)),
          ),

          // Profile button
          Positioned(
            top: MediaQuery.of(context).size.height * 0.025,
            right: MediaQuery.of(context).size.height * 0.025,
            child: Container(height: 50, width: 50, color: Colors.grey),
          ),

          // Options button
          Positioned(
            top: MediaQuery.of(context).size.height * 0.025,
            left: MediaQuery.of(context).size.height * 0.025,
            child: Container(height: 50, width: 50, color: Colors.grey),
          ),

          // Mode Switcher
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.025,
            child: Container(height: 50, width: 200, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
