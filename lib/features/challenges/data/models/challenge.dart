/// Represents a community challenge
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType challengeType;
  final DateTime startDate;
  final DateTime endDate;
  final int targetValue;
  final String targetUnit;
  final bool isPublic;
  final String? createdBy;
  final ChallengeStatus status;
  final int maxParticipants;
  final DateTime createdAt;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.challengeType,
    required this.startDate,
    required this.endDate,
    required this.targetValue,
    required this.targetUnit,
    this.isPublic = true,
    this.createdBy,
    this.status = ChallengeStatus.active,
    this.maxParticipants = 0,
    required this.createdAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      challengeType: ChallengeTypeX.fromString(
        json['challenge_type'] as String,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      targetValue: json['target_value'] as int,
      targetUnit: json['target_unit'] as String,
      isPublic: json['is_public'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      status: ChallengeStatusX.fromString(json['status'] as String),
      maxParticipants: json['max_participants'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Check if challenge is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == ChallengeStatus.active &&
        now.isAfter(startDate) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Get remaining days
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays + 1;
  }
}

/// Challenge types
enum ChallengeType { streak, dhikr, quran, custom }

extension ChallengeTypeX on ChallengeType {
  String get value {
    switch (this) {
      case ChallengeType.streak:
        return 'streak';
      case ChallengeType.dhikr:
        return 'dhikr';
      case ChallengeType.quran:
        return 'quran';
      case ChallengeType.custom:
        return 'custom';
    }
  }

  String get displayName {
    switch (this) {
      case ChallengeType.streak:
        return 'Streak Challenge';
      case ChallengeType.dhikr:
        return 'Dhikr Challenge';
      case ChallengeType.quran:
        return 'Quran Challenge';
      case ChallengeType.custom:
        return 'Custom Challenge';
    }
  }

  String get icon {
    switch (this) {
      case ChallengeType.streak:
        return '🔥';
      case ChallengeType.dhikr:
        return '📿';
      case ChallengeType.quran:
        return '📖';
      case ChallengeType.custom:
        return '🎯';
    }
  }

  static ChallengeType fromString(String value) {
    switch (value) {
      case 'streak':
        return ChallengeType.streak;
      case 'dhikr':
        return ChallengeType.dhikr;
      case 'quran':
        return ChallengeType.quran;
      default:
        return ChallengeType.custom;
    }
  }
}

/// Challenge status
enum ChallengeStatus { draft, active, completed, cancelled }

extension ChallengeStatusX on ChallengeStatus {
  String get value {
    switch (this) {
      case ChallengeStatus.draft:
        return 'draft';
      case ChallengeStatus.active:
        return 'active';
      case ChallengeStatus.completed:
        return 'completed';
      case ChallengeStatus.cancelled:
        return 'cancelled';
    }
  }

  static ChallengeStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return ChallengeStatus.draft;
      case 'active':
        return ChallengeStatus.active;
      case 'completed':
        return ChallengeStatus.completed;
      case 'cancelled':
        return ChallengeStatus.cancelled;
      default:
        return ChallengeStatus.active;
    }
  }
}

/// Represents a user's participation in a challenge
class ChallengeParticipant {
  final String id;
  final String challengeId;
  final String userId;
  final int currentProgress;
  final int bestProgress;
  final bool isActive;
  final DateTime? completedAt;
  final int? currentRank;
  final DateTime joinedAt;

  // Optional: populated from join
  final String? displayName;

  ChallengeParticipant({
    required this.id,
    required this.challengeId,
    required this.userId,
    this.currentProgress = 0,
    this.bestProgress = 0,
    this.isActive = true,
    this.completedAt,
    this.currentRank,
    required this.joinedAt,
    this.displayName,
  });

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipant(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String,
      currentProgress: json['current_progress'] as int? ?? 0,
      bestProgress: json['best_progress'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      currentRank: json['current_rank'] as int?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      displayName: json['display_name'] as String?,
    );
  }

  bool get hasCompleted => completedAt != null;
}

/// Leaderboard entry (from RPC)
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int currentProgress;
  final int rank;
  final DateTime? completedAt;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.currentProgress,
    required this.rank,
    this.completedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String? ?? 'Anonymous',
      currentProgress: json['current_progress'] as int,
      rank: json['rank'] as int,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}
