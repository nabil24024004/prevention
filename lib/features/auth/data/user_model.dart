class UserProfile {
  final String id;
  final String? username;
  final DateTime startDate;
  final DateTime? lastRelapseDate;
  final int currentStreakDays;
  final int bestStreakDays;

  UserProfile({
    required this.id,
    this.username,
    required this.startDate,
    this.lastRelapseDate,
    required this.currentStreakDays,
    required this.bestStreakDays,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      startDate: DateTime.parse(json['start_date']),
      lastRelapseDate: json['last_relapse_date'] != null
          ? DateTime.parse(json['last_relapse_date'])
          : null,
      currentStreakDays: json['current_streak_days'] ?? 0,
      bestStreakDays: json['best_streak_days'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'start_date': startDate.toIso8601String(),
      'last_relapse_date': lastRelapseDate?.toIso8601String(),
      'current_streak_days': currentStreakDays,
      'best_streak_days': bestStreakDays,
    };
  }
}
