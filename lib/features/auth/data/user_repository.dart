import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_model.dart';

final userRepositoryProvider = Provider((ref) => UserRepository(Supabase.instance.client));

final userProfileStreamProvider = StreamProvider<UserProfile>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserProfileStream();
});

class UserRepository {
  final SupabaseClient _client;

  UserRepository(this._client);

  Stream<UserProfile> getUserProfileStream() {
    final userId = _client.auth.currentUser!.id;
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => UserProfile.fromJson(data.first));
  }
}
