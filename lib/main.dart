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
          surface: const Color.fromARGB(255, 28, 28, 28),
          secondary: const Color.fromARGB(255, 32, 32, 32),
        ),
      ),
      home: const HomePage(),
    );
  }
}
