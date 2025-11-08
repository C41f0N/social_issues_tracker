import 'package:flutter/material.dart';
import 'package:social_issues_tracker/pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color.fromARGB(255, 73, 207, 247),
          secondary: const Color.fromARGB(255, 39, 39, 39),
          tertiary: const Color.fromARGB(255, 195, 116, 225),
          surface: const Color.fromARGB(255, 20, 20, 20),
        ),
      ),
      home: HomePage(),
    );
  }
}
