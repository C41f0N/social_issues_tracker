import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/pages/auth_gate.dart';
// import 'package:social_issues_tracker/data/supabase_functions_client.dart'; // (pending implementation)
import 'package:social_issues_tracker/auth/auth_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hnucjbjbjqctpxfibsdb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhudWNqYmpianFjdHB4Zmlic2RiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4MDM3NDcsImV4cCI6MjA3NjM3OTc0N30.b37lGqba3IO0nKpStP3Y-wL24h8JoCZKU-bhMaD0VCM',
  );

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
