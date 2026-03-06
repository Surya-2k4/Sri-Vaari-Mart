import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/profile_model.dart';

final profileViewModelProvider =
    StateNotifierProvider<ProfileViewModel, AsyncValue<ProfileModel?>>(
      (ref) => ProfileViewModel(),
    );

class ProfileViewModel extends StateNotifier<AsyncValue<ProfileModel?>> {
  ProfileViewModel() : super(const AsyncValue.loading()) {
    loadProfile();
  }

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> logout() async {
    await _client.auth.signOut();
    state = const AsyncValue.data(null); // 🔑 clear old profile data
  }

  Future<void> loadProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        await _createProfile(user);
      } else {
        state = AsyncValue.data(ProfileModel.fromMap(data));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _createProfile(User user) async {
    await _client.from('profiles').insert({'id': user.id, 'email': user.email});

    await loadProfile();
  }

  Future<void> updateProfile({
    String? fullName,
    String? address,
    String? phone,
  }) async {
    try {
      final profile = state.value;
      if (profile == null) {
        print('Profile is null, cannot update');
        return;
      }

      final Map<String, dynamic> updates = {};
      if (fullName != null) updates['full_name'] = fullName;
      if (address != null) updates['address'] = address;
      if (phone != null) {
        // Convert phone string to int for database
        final phoneInt = int.tryParse(phone);
        if (phoneInt != null) {
          updates['phone'] = phoneInt;
        }
      }

      if (updates.isEmpty) {
        print('No updates to perform');
        return;
      }

      print('Updating profile with: $updates');

      final response = await _client
          .from('profiles')
          .update(updates)
          .eq('id', profile.id)
          .select();

      print('Update response: $response');

      await loadProfile();
    } catch (e, st) {
      print('Error updating profile: $e');
      print('Stack trace: $st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateName(String name) async {
    return updateProfile(fullName: name);
  }
}
