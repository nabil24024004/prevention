/// Status of a partnership
enum PartnershipStatus { pending, active, declined, ended }

/// Represents an accountability partnership between two users
class Partnership {
  final String id;
  final String userId;
  final String? partnerId;
  final PartnershipStatus status;
  final String? inviteCode;

  // Notification preferences
  final bool notifyOnRelapse;
  final bool notifyOnMissedCheckin;
  final bool notifyOnStreakMilestone;
  final bool anonymousMode;

  // Partner info (populated when fetching)
  final String? partnerDisplayName;
  final String? partnerAvatarUrl;
  final int? partnerCurrentStreak;

  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;

  Partnership({
    required this.id,
    required this.userId,
    this.partnerId,
    this.status = PartnershipStatus.pending,
    this.inviteCode,
    this.notifyOnRelapse = true,
    this.notifyOnMissedCheckin = true,
    this.notifyOnStreakMilestone = true,
    this.anonymousMode = false,
    this.partnerDisplayName,
    this.partnerAvatarUrl,
    this.partnerCurrentStreak,
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
  });

  factory Partnership.fromJson(Map<String, dynamic> json) {
    return Partnership(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      partnerId: json['partner_id'] as String?,
      status: PartnershipStatusX.fromString(
        json['status'] as String? ?? 'pending',
      ),
      inviteCode: json['invite_code'] as String?,
      notifyOnRelapse: json['notify_on_relapse'] as bool? ?? true,
      notifyOnMissedCheckin: json['notify_on_missed_checkin'] as bool? ?? true,
      notifyOnStreakMilestone:
          json['notify_on_streak_milestone'] as bool? ?? true,
      anonymousMode: json['anonymous_mode'] as bool? ?? false,
      partnerDisplayName: json['partner_display_name'] as String?,
      partnerAvatarUrl: json['partner_avatar_url'] as String?,
      partnerCurrentStreak: json['partner_current_streak'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'partner_id': partnerId,
      'status': status.value,
      'invite_code': inviteCode,
      'notify_on_relapse': notifyOnRelapse,
      'notify_on_missed_checkin': notifyOnMissedCheckin,
      'notify_on_streak_milestone': notifyOnStreakMilestone,
      'anonymous_mode': anonymousMode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
    };
  }

  Partnership copyWith({
    String? id,
    String? userId,
    String? partnerId,
    PartnershipStatus? status,
    String? inviteCode,
    bool? notifyOnRelapse,
    bool? notifyOnMissedCheckin,
    bool? notifyOnStreakMilestone,
    bool? anonymousMode,
    String? partnerDisplayName,
    String? partnerAvatarUrl,
    int? partnerCurrentStreak,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
  }) {
    return Partnership(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partnerId: partnerId ?? this.partnerId,
      status: status ?? this.status,
      inviteCode: inviteCode ?? this.inviteCode,
      notifyOnRelapse: notifyOnRelapse ?? this.notifyOnRelapse,
      notifyOnMissedCheckin:
          notifyOnMissedCheckin ?? this.notifyOnMissedCheckin,
      notifyOnStreakMilestone:
          notifyOnStreakMilestone ?? this.notifyOnStreakMilestone,
      anonymousMode: anonymousMode ?? this.anonymousMode,
      partnerDisplayName: partnerDisplayName ?? this.partnerDisplayName,
      partnerAvatarUrl: partnerAvatarUrl ?? this.partnerAvatarUrl,
      partnerCurrentStreak: partnerCurrentStreak ?? this.partnerCurrentStreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}

/// Extension for PartnershipStatus serialization
extension PartnershipStatusX on PartnershipStatus {
  String get value {
    switch (this) {
      case PartnershipStatus.pending:
        return 'pending';
      case PartnershipStatus.active:
        return 'active';
      case PartnershipStatus.declined:
        return 'declined';
      case PartnershipStatus.ended:
        return 'ended';
    }
  }

  static PartnershipStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return PartnershipStatus.pending;
      case 'active':
        return PartnershipStatus.active;
      case 'declined':
        return PartnershipStatus.declined;
      case 'ended':
        return PartnershipStatus.ended;
      default:
        return PartnershipStatus.pending;
    }
  }
}
