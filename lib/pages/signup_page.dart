import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_issues_tracker/auth/auth_notifier.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, required this.onSwitchToLogin});
  final VoidCallback onSwitchToLogin;
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, auth, _) {
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign Up',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Username required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Email required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
                obscureText: true,
                validator: (v) =>
                    v != _passwordController.text ? 'Passwords differ' : null,
              ),
              const SizedBox(height: 16),
              if (auth.errorMessage != null)
                Text(
                  auth.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: auth.loading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        await auth.signup(
                          email: _emailController.text,
                          password: _passwordController.text,
                          fullName: _nameController.text,
                          username: _usernameController.text,
                        );
                      },
                child: auth.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create account'),
              ),
              TextButton(
                onPressed: auth.loading ? null : widget.onSwitchToLogin,
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        );
      },
    );
  }
}
