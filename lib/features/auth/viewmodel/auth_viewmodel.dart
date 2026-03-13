import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/user_model.dart';

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AsyncValue<AppUser?>>(
      (ref) => AuthViewModel(),
    );

class AuthViewModel extends StateNotifier<AsyncValue<AppUser?>> {
  AuthViewModel() : super(const AsyncValue.loading()) {
    _restoreSession();
  }

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> _restoreSession() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      final user = session.user;
      state = AsyncValue.data(AppUser(id: user.id, email: user.email ?? ''));
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    try {
      state = const AsyncValue.loading();
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final user = response.user!;
      state = AsyncValue.data(AppUser(id: user.id, email: user.email ?? ''));
    } on AuthException catch (e, st) {
      final message = e.message.toLowerCase();

      if (message.contains('already registered')) {
        try {
          await signIn(email, password);
          return;
        } on AuthException catch (signInError, signInStack) {
          if (signInError.message.toLowerCase().contains(
            'invalid login credentials',
          )) {
            state = AsyncValue.error(
              AuthException(
                'An account with this email already exists. Try signing in or resetting your password.',
              ),
              signInStack,
            );
          } else {
            state = AsyncValue.error(signInError, signInStack);
          }
        }
        return;
      }

      state = AsyncValue.error(e, st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user!;
      state = AsyncValue.data(AppUser(id: user.id, email: user.email ?? ''));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo:
            'http://localhost:49435', // Update this for your production URL
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      state = const AsyncValue.loading();
      await _client.auth.resetPasswordForEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
