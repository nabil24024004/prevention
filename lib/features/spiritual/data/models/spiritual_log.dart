/// Represents a daily spiritual activity log
class SpiritualLog {
  final String id;
  final String userId;
  final DateTime logDate;

  // Salah tracking
  final bool fajrPrayed;
  final bool dhuhrPrayed;
  final bool asrPrayed;
  final bool maghribPrayed;
  final bool ishaPrayed;

  // Dhikr counts
  final int subhanallahCount;
  final int alhamdulillahCount;
  final int allahuakbarCount;
  final int istighfarCount;
  final int salawatCount;
  final int customDhikrCount;
  final String? customDhikrText;

  // Quran reading
  final int quranPagesRead;
  final int quranMinutesRead;

  // Adhkar completed
  final bool morningAdhkarCompleted;
  final bool eveningAdhkarCompleted;
  final bool sleepAdhkarCompleted;

  // Notes
  final String? notes;

  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  SpiritualLog({
    required this.id,
    required this.userId,
    required this.logDate,
    this.fajrPrayed = false,
    this.dhuhrPrayed = false,
    this.asrPrayed = false,
    this.maghribPrayed = false,
    this.ishaPrayed = false,
    this.subhanallahCount = 0,
    this.alhamdulillahCount = 0,
    this.allahuakbarCount = 0,
    this.istighfarCount = 0,
    this.salawatCount = 0,
    this.customDhikrCount = 0,
    this.customDhikrText,
    this.quranPagesRead = 0,
    this.quranMinutesRead = 0,
    this.morningAdhkarCompleted = false,
    this.eveningAdhkarCompleted = false,
    this.sleepAdhkarCompleted = false,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory SpiritualLog.fromJson(Map<String, dynamic> json) {
    return SpiritualLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      fajrPrayed: json['fajr_prayed'] as bool? ?? false,
      dhuhrPrayed: json['dhuhr_prayed'] as bool? ?? false,
      asrPrayed: json['asr_prayed'] as bool? ?? false,
      maghribPrayed: json['maghrib_prayed'] as bool? ?? false,
      ishaPrayed: json['isha_prayed'] as bool? ?? false,
      subhanallahCount: json['subhanallah_count'] as int? ?? 0,
      alhamdulillahCount: json['alhamdulillah_count'] as int? ?? 0,
      allahuakbarCount: json['allahuakbar_count'] as int? ?? 0,
      istighfarCount: json['istighfar_count'] as int? ?? 0,
      salawatCount: json['salawat_count'] as int? ?? 0,
      customDhikrCount: json['custom_dhikr_count'] as int? ?? 0,
      customDhikrText: json['custom_dhikr_text'] as String?,
      quranPagesRead: json['quran_pages_read'] as int? ?? 0,
      quranMinutesRead: json['quran_minutes_read'] as int? ?? 0,
      morningAdhkarCompleted:
          json['morning_adhkar_completed'] as bool? ?? false,
      eveningAdhkarCompleted:
          json['evening_adhkar_completed'] as bool? ?? false,
      sleepAdhkarCompleted: json['sleep_adhkar_completed'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Get count of prayers completed today
  int get prayersCompleted {
    int count = 0;
    if (fajrPrayed) count++;
    if (dhuhrPrayed) count++;
    if (asrPrayed) count++;
    if (maghribPrayed) count++;
    if (ishaPrayed) count++;
    return count;
  }

  /// Get total dhikr count
  int get totalDhikrCount {
    return subhanallahCount +
        alhamdulillahCount +
        allahuakbarCount +
        istighfarCount +
        salawatCount +
        customDhikrCount;
  }

  /// Get adhkar completion count
  int get adhkarCompleted {
    int count = 0;
    if (morningAdhkarCompleted) count++;
    if (eveningAdhkarCompleted) count++;
    if (sleepAdhkarCompleted) count++;
    return count;
  }
}

/// Types of dhikr available
enum DhikrType {
  subhanallah,
  alhamdulillah,
  allahuakbar,
  istighfar,
  salawat,
  custom,
}

extension DhikrTypeX on DhikrType {
  String get arabicText {
    switch (this) {
      case DhikrType.subhanallah:
        return 'سُبْحَانَ اللهِ';
      case DhikrType.alhamdulillah:
        return 'الحَمْدُ للهِ';
      case DhikrType.allahuakbar:
        return 'اللهُ أَكْبَرُ';
      case DhikrType.istighfar:
        return 'أَسْتَغْفِرُ اللهَ';
      case DhikrType.salawat:
        return 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ';
      case DhikrType.custom:
        return '';
    }
  }

  String get transliteration {
    switch (this) {
      case DhikrType.subhanallah:
        return 'SubhanAllah';
      case DhikrType.alhamdulillah:
        return 'Alhamdulillah';
      case DhikrType.allahuakbar:
        return 'Allahu Akbar';
      case DhikrType.istighfar:
        return 'Astaghfirullah';
      case DhikrType.salawat:
        return 'Allahumma Salli Ala Muhammad';
      case DhikrType.custom:
        return 'Custom';
    }
  }

  String get meaning {
    switch (this) {
      case DhikrType.subhanallah:
        return 'Glory be to Allah';
      case DhikrType.alhamdulillah:
        return 'All praise is due to Allah';
      case DhikrType.allahuakbar:
        return 'Allah is the Greatest';
      case DhikrType.istighfar:
        return 'I seek forgiveness from Allah';
      case DhikrType.salawat:
        return 'O Allah, send blessings upon Muhammad';
      case DhikrType.custom:
        return 'Custom dhikr';
    }
  }

  String get dbColumn {
    switch (this) {
      case DhikrType.subhanallah:
        return 'subhanallah';
      case DhikrType.alhamdulillah:
        return 'alhamdulillah';
      case DhikrType.allahuakbar:
        return 'allahuakbar';
      case DhikrType.istighfar:
        return 'istighfar';
      case DhikrType.salawat:
        return 'salawat';
      case DhikrType.custom:
        return 'custom_dhikr';
    }
  }
}

/// Prayer names
enum Prayer { fajr, dhuhr, asr, maghrib, isha }

extension PrayerX on Prayer {
  String get displayName {
    switch (this) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
    }
  }

  String get arabicName {
    switch (this) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
    }
  }

  String get dbColumn {
    switch (this) {
      case Prayer.fajr:
        return 'fajr';
      case Prayer.dhuhr:
        return 'dhuhr';
      case Prayer.asr:
        return 'asr';
      case Prayer.maghrib:
        return 'maghrib';
      case Prayer.isha:
        return 'isha';
    }
  }
}
