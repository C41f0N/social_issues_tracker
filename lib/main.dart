import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/pages/auth_gate.dart';
import 'package:social_issues_tracker/auth/auth_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalData()),
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

ColorScheme colorScheme = ColorScheme.dark(
  primary: const Color.fromARGB(255, 73, 207, 247),
  secondary: const Color.fromARGB(255, 39, 39, 39),
  tertiary: const Color.fromARGB(255, 195, 116, 225),
  surface: const Color.fromARGB(255, 20, 20, 20),
  onError: Colors.white,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: colorScheme,
        inputDecorationTheme: InputDecorationTheme(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.secondary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.surface),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
