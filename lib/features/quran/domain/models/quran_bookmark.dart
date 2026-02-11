class QuranBookmark {
  final String id;
  final String userId;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final DateTime createdAt;

  QuranBookmark({
    required this.id,
    required this.userId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.createdAt,
  });

  factory QuranBookmark.fromJson(Map<String, dynamic> json) {
    return QuranBookmark(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      surahNumber: json['surah_number'] as int,
      ayahNumber: json['ayah_number'] as int,
      surahName: json['surah_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surah_number': surahNumber,
      'ayah_number': ayahNumber,
      'surah_name': surahName,
    };
  }
}
