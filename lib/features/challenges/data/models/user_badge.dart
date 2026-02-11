/// User badge model
class UserBadge {
  final String id;
  final String userId;
  final String badgeType;
  final String badgeName;
  final String? badgeDescription;
  final String? badgeIcon;
  final String? challengeId;
  final int? streakMilestone;
  final bool isFeatured;
  final DateTime earnedAt;

  UserBadge({
    required this.id,
    required this.userId,
    required this.badgeType,
    required this.badgeName,
    this.badgeDescription,
    this.badgeIcon,
    this.challengeId,
    this.streakMilestone,
    this.isFeatured = false,
    required this.earnedAt,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeType: json['badge_type'] as String,
      badgeName: json['badge_name'] as String,
      badgeDescription: json['badge_description'] as String?,
      badgeIcon: json['badge_icon'] as String?,
      challengeId: json['challenge_id'] as String?,
      streakMilestone: json['streak_milestone'] as int?,
      isFeatured: json['is_featured'] as bool? ?? false,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }

  /// Get display icon for badge based on type
  String get displayIcon {
    if (badgeIcon != null) return badgeIcon!;

    // Default icons based on type
    switch (badgeType) {
      case 'streak':
        return '🔥';
      case 'challenge':
        return '🏆';
      case 'dhikr':
        return '📿';
      case 'quran':
        return '📖';
      case 'milestone':
        return '⭐';
      default:
        return '🎖️';
    }
  }
}

/// Pre-defined badge types
class BadgeTypes {
  static const String streak = 'streak';
  static const String challenge = 'challenge';
  static const String dhikr = 'dhikr';
  static const String quran = 'quran';
  static const String milestone = 'milestone';
  static const String community = 'community';
}

/// Pre-defined badges
class Badges {
  // Streak badges
  static const week = ('streak', 'Week Warrior', '7-day streak', '🔥', 7);
  static const month = ('streak', 'Monthly Master', '30-day streak', '💪', 30);
  static const quarter = (
    'streak',
    'Quarterly Champion',
    '90-day streak',
    '🏅',
    90,
  );
  static const year = ('streak', 'Yearly Legend', '365-day streak', '👑', 365);

  // Dhikr badges
  static const dhikr1k = (
    'dhikr',
    'Dhikr Devotee',
    '1,000 total dhikr',
    '📿',
    1000,
  );
  static const dhikr10k = (
    'dhikr',
    'Dhikr Master',
    '10,000 total dhikr',
    '✨',
    10000,
  );

  // Challenge badges
  static const firstChallenge = (
    'challenge',
    'Challenger',
    'First challenge completed',
    '🎯',
    1,
  );
  static const fiveChallenges = (
    'challenge',
    'Challenge Seeker',
    '5 challenges completed',
    '🏆',
    5,
  );
}
