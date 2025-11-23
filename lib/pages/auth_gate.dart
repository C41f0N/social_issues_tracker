import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/auth/auth_notifier.dart';
import 'package:social_issues_tracker/data/local_data.dart';
import 'package:social_issues_tracker/pages/login_page.dart';
import 'package:social_issues_tracker/pages/signup_page.dart';
import 'package:social_issues_tracker/pages/home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool showLogin = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthNotifier>(context, listen: false);
    final local = Provider.of<LocalData>(context, listen: false);
    if (auth.initializing) {
      auth.init(local); // ensure init runs once
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, auth, _) {
        if (auth.initializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.isAuthenticated) {
          return HomePage();
        }
        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: showLogin
                      ? LoginPage(
                          key: const ValueKey('login'),
                          onSwitchToSignup: () =>
                              setState(() => showLogin = false),
                        )
                      : SignupPage(
                          key: const ValueKey('signup'),
                          onSwitchToLogin: () =>
                              setState(() => showLogin = true),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
