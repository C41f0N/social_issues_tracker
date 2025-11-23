import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_issues_tracker/data/local_data.dart';

class AuthNotifier extends ChangeNotifier {
  Session? _session;
  User? _user;
  bool initializing = true;
  bool loading = false;
  String? errorMessage;

  Session? get session => _session;
  User? get user => _user;

  Future<void> init(LocalData local) async {
    final client = Supabase.instance.client;
    _session = client.auth.currentSession;
    _user = _session?.user;
    if (_user != null) {
      local.loggedInUserId = _user!.id; // replace dummy
    }
    client.auth.onAuthStateChange.listen((data) {
      final newSession = data.session;
      _session = newSession;
      _user = newSession?.user;
      if (_user != null) {
        local.loggedInUserId = _user!.id;
      }
      notifyListeners();
    });
    initializing = false;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    errorMessage = null;
    loading = true;
    notifyListeners();
    try {
      final client = Supabase.instance.client;
      final res = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.session == null) {
        errorMessage = 'Login failed.';
      } else {
        _session = res.session;
        _user = _session?.user;
      }
    } on AuthException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Unexpected error';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    errorMessage = null;
    loading = true;
    notifyListeners();
    try {
      final client = Supabase.instance.client;
      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName},
      );
      if (res.session == null) {
        // If email confirmation enabled, session may be null.
        errorMessage = 'Check your email to confirm account.';
      } else {
        _session = res.session;
        _user = _session?.user;
      }
    } on AuthException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Unexpected error';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    _session = null;
    _user = null;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
