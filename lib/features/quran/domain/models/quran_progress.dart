class QuranProgress {
  final int lastSurahNumber;
  final int lastAyahNumber;
  final DateTime lastReadAt;

  QuranProgress({
    required this.lastSurahNumber,
    required this.lastAyahNumber,
    required this.lastReadAt,
  });

  factory QuranProgress.fromJson(Map<String, dynamic> json) {
    return QuranProgress(
      lastSurahNumber: json['lastSurahNumber'] as int,
      lastAyahNumber: json['lastAyahNumber'] as int,
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastSurahNumber': lastSurahNumber,
      'lastAyahNumber': lastAyahNumber,
      'lastReadAt': lastReadAt.toIso8601String(),
    };
  }
}
