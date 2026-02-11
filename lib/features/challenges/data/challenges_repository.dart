import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/challenge.dart';
import 'models/user_badge.dart';

/// Repository for community challenges
class ChallengesRepository {
  final SupabaseClient _client;

  ChallengesRepository(this._client);

  String get _userId => _client.auth.currentUser?.id ?? '';

  /// Get all active public challenges
  Future<List<Challenge>> getActiveChallenges() async {
    final response = await _client
        .from('challenges')
        .select()
        .eq('status', 'active')
        .eq('is_public', true)
        .gte('end_date', DateTime.now().toIso8601String().split('T')[0])
        .order('start_date');

    return (response as List).map((json) => Challenge.fromJson(json)).toList();
  }

  /// Get user's active challenges
  Future<List<Map<String, dynamic>>> getMyChallenges() async {
    final response = await _client.rpc('get_my_active_challenges');

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get challenge by ID
  Future<Challenge?> getChallengeById(String id) async {
    final response = await _client
        .from('challenges')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Challenge.fromJson(response);
  }

  /// Join a challenge
  Future<bool> joinChallenge(String challengeId) async {
    final result = await _client.rpc(
      'join_challenge',
      params: {'p_challenge_id': challengeId},
    );

    return result['success'] == true;
  }

  /// Leave a challenge
  Future<void> leaveChallenge(String challengeId) async {
    await _client
        .from('challenge_participants')
        .update({'is_active': false})
        .eq('challenge_id', challengeId)
        .eq('user_id', _userId);
  }

  /// Update progress in a challenge
  Future<Map<String, dynamic>> updateProgress(
    String challengeId,
    int progress,
  ) async {
    final result = await _client.rpc(
      'update_challenge_progress',
      params: {'p_challenge_id': challengeId, 'p_progress': progress},
    );

    return result as Map<String, dynamic>;
  }

  /// Get challenge leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard(
    String challengeId, {
    int limit = 20,
  }) async {
    final response = await _client.rpc(
      'get_challenge_leaderboard',
      params: {'p_challenge_id': challengeId, 'p_limit': limit},
    );

    return (response as List)
        .map((json) => LeaderboardEntry.fromJson(json))
        .toList();
  }

  /// Get my participation in a challenge
  Future<ChallengeParticipant?> getMyParticipation(String challengeId) async {
    final response = await _client
        .from('challenge_participants')
        .select()
        .eq('challenge_id', challengeId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return ChallengeParticipant.fromJson(response);
  }

  /// Create a new challenge
  Future<Challenge> createChallenge({
    required String title,
    required String description,
    required ChallengeType type,
    required DateTime startDate,
    required DateTime endDate,
    required int targetValue,
    String targetUnit = 'days',
    bool isPublic = true,
    int maxParticipants = 0,
  }) async {
    final response = await _client
        .from('challenges')
        .insert({
          'title': title,
          'description': description,
          'challenge_type': type.value,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'target_value': targetValue,
          'target_unit': targetUnit,
          'is_public': isPublic,
          'created_by': _userId,
          'max_participants': maxParticipants,
        })
        .select()
        .single();

    return Challenge.fromJson(response);
  }

  /// Get user's badges
  Future<List<UserBadge>> getMyBadges() async {
    final response = await _client
        .from('user_badges')
        .select()
        .eq('user_id', _userId)
        .order('earned_at', ascending: false);

    return (response as List).map((json) => UserBadge.fromJson(json)).toList();
  }

  /// Award a badge
  Future<void> awardBadge({
    required String badgeType,
    required String badgeName,
    String? description,
    String? icon,
    String? challengeId,
    int? streakMilestone,
  }) async {
    await _client.rpc(
      'award_badge',
      params: {
        'p_badge_type': badgeType,
        'p_badge_name': badgeName,
        'p_description': description,
        'p_icon': icon,
        'p_challenge_id': challengeId,
        'p_streak': streakMilestone,
      },
    );
  }
}

// ============================================
// RIVERPOD PROVIDERS
// ============================================

/// Repository provider
final challengesRepositoryProvider = Provider<ChallengesRepository>((ref) {
  return ChallengesRepository(Supabase.instance.client);
});

/// Active public challenges provider
final activeChallengesProvider = FutureProvider<List<Challenge>>((ref) {
  return ref.read(challengesRepositoryProvider).getActiveChallenges();
});

/// User's active challenges provider
final myChallengesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(challengesRepositoryProvider).getMyChallenges();
});

/// User's badges provider
final myBadgesProvider = FutureProvider<List<UserBadge>>((ref) {
  return ref.read(challengesRepositoryProvider).getMyBadges();
});

/// Single challenge provider
final challengeProvider = FutureProvider.family<Challenge?, String>((ref, id) {
  return ref.read(challengesRepositoryProvider).getChallengeById(id);
});

/// Leaderboard provider
final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, challengeId) {
      return ref.read(challengesRepositoryProvider).getLeaderboard(challengeId);
    });

/// My participation in a challenge
final myParticipationProvider =
    FutureProvider.family<ChallengeParticipant?, String>((ref, challengeId) {
      return ref
          .read(challengesRepositoryProvider)
          .getMyParticipation(challengeId);
    });
