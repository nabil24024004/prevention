import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/user_model.dart';

/// Service for caching data locally to support offline mode.
class LocalCacheService {
  static const _userProfileKey = 'cached_user_profile';
  static const _weeklyCheckInsKey = 'cached_weekly_checkins';
  static const _weeklyRelapsesKey = 'cached_weekly_relapses';

  final SharedPreferences _prefs;

  LocalCacheService(this._prefs);

  // ============ User Profile ============

  /// Saves user profile to local cache.
  Future<void> cacheUserProfile(UserProfile profile) async {
    final json = {
      'id': profile.id,
      'username': profile.username,
      'start_date': profile.startDate.toIso8601String(),
      'last_relapse_date': profile.lastRelapseDate?.toIso8601String(),
      'current_streak_days': profile.currentStreakDays,
      'best_streak_days': profile.bestStreakDays,
    };
    await _prefs.setString(_userProfileKey, jsonEncode(json));
  }

  /// Retrieves cached user profile (or null if not cached).
  UserProfile? getCachedUserProfile() {
    final jsonStr = _prefs.getString(_userProfileKey);
    if (jsonStr == null) return null;
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  // ============ Weekly Data ============

  /// Saves weekly check-in dates.
  Future<void> cacheWeeklyCheckIns(List<String> dates) async {
    await _prefs.setStringList(_weeklyCheckInsKey, dates);
  }

  /// Retrieves cached weekly check-ins.
  List<String> getCachedWeeklyCheckIns() {
    return _prefs.getStringList(_weeklyCheckInsKey) ?? [];
  }

  /// Saves weekly relapse dates.
  Future<void> cacheWeeklyRelapses(List<String> dates) async {
    await _prefs.setStringList(_weeklyRelapsesKey, dates);
  }

  /// Retrieves cached weekly relapses.
  List<String> getCachedWeeklyRelapses() {
    return _prefs.getStringList(_weeklyRelapsesKey) ?? [];
  }

  /// Clears all cached data (useful on logout).
  Future<void> clearCache() async {
    await _prefs.remove(_userProfileKey);
    await _prefs.remove(_weeklyCheckInsKey);
    await _prefs.remove(_weeklyRelapsesKey);
  }
}
