class Ayah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final bool sajda;
  final String? audio;
  final List<String>? audioSecondary;

  /// These are populated from the Juz API where each ayah carries its surah info
  final int surahNumber;
  final String surahName;

  Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    required this.sajda,
    this.audio,
    this.audioSecondary,
    this.surahNumber = 0,
    this.surahName = '',
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    // The Juz endpoint nests surah info inside each ayah
    final surahData = json['surah'];
    return Ayah(
      number: json['number'] as int,
      text: json['text'] as String,
      numberInSurah: json['numberInSurah'] as int,
      juz: json['juz'] as int,
      manzil: json['manzil'] as int,
      page: json['page'] as int,
      ruku: json['ruku'] as int,
      hizbQuarter: json['hizbQuarter'] as int,
      sajda: json['sajda'] is bool ? json['sajda'] as bool : false,
      audio: json['audio'] as String?,
      audioSecondary: (json['audioSecondary'] as List?)
          ?.map((e) => e as String)
          .toList(),
      surahNumber: surahData != null ? surahData['number'] as int : 0,
      surahName: surahData != null
          ? surahData['englishName'] as String? ?? ''
          : '',
    );
  }
}
