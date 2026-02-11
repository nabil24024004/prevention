/// Adhkar category types
enum AdhkarCategory { morning, evening, sleep, protection, general, afterSalah }

extension AdhkarCategoryX on AdhkarCategory {
  String get value {
    switch (this) {
      case AdhkarCategory.morning:
        return 'morning';
      case AdhkarCategory.evening:
        return 'evening';
      case AdhkarCategory.sleep:
        return 'sleep';
      case AdhkarCategory.protection:
        return 'protection';
      case AdhkarCategory.general:
        return 'general';
      case AdhkarCategory.afterSalah:
        return 'after_salah';
    }
  }

  String get displayName {
    switch (this) {
      case AdhkarCategory.morning:
        return 'Morning Adhkar';
      case AdhkarCategory.evening:
        return 'Evening Adhkar';
      case AdhkarCategory.sleep:
        return 'Before Sleep';
      case AdhkarCategory.protection:
        return 'Protection';
      case AdhkarCategory.general:
        return 'General Duas';
      case AdhkarCategory.afterSalah:
        return 'After Prayer';
    }
  }

  String get arabicName {
    switch (this) {
      case AdhkarCategory.morning:
        return 'أذكار الصباح';
      case AdhkarCategory.evening:
        return 'أذكار المساء';
      case AdhkarCategory.sleep:
        return 'أذكار النوم';
      case AdhkarCategory.protection:
        return 'أذكار الحماية';
      case AdhkarCategory.general:
        return 'أدعية عامة';
      case AdhkarCategory.afterSalah:
        return 'أذكار بعد الصلاة';
    }
  }

  static AdhkarCategory fromString(String value) {
    switch (value) {
      case 'morning':
        return AdhkarCategory.morning;
      case 'evening':
        return AdhkarCategory.evening;
      case 'sleep':
        return AdhkarCategory.sleep;
      case 'protection':
        return AdhkarCategory.protection;
      case 'general':
        return AdhkarCategory.general;
      case 'after_salah':
        return AdhkarCategory.afterSalah;
      default:
        return AdhkarCategory.general;
    }
  }
}

/// Represents a single adhkar/dua item
class AdhkarItem {
  final String id;
  final AdhkarCategory category;
  final String titleArabic;
  final String titleEnglish;
  final String contentArabic;
  final String? contentTransliteration;
  final String contentEnglish;
  final int repeatCount;
  final String? source;
  final String? benefit;
  final int displayOrder;

  AdhkarItem({
    required this.id,
    required this.category,
    required this.titleArabic,
    required this.titleEnglish,
    required this.contentArabic,
    this.contentTransliteration,
    required this.contentEnglish,
    this.repeatCount = 1,
    this.source,
    this.benefit,
    this.displayOrder = 0,
  });

  factory AdhkarItem.fromJson(Map<String, dynamic> json) {
    return AdhkarItem(
      id: json['id'] as String,
      category: AdhkarCategoryX.fromString(json['category'] as String),
      titleArabic: json['title_arabic'] as String,
      titleEnglish: json['title_english'] as String,
      contentArabic: json['content_arabic'] as String,
      contentTransliteration: json['content_transliteration'] as String?,
      contentEnglish: json['content_english'] as String,
      repeatCount: json['repeat_count'] as int? ?? 1,
      source: json['source'] as String?,
      benefit: json['benefit'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.value,
      'title_arabic': titleArabic,
      'title_english': titleEnglish,
      'content_arabic': contentArabic,
      'content_transliteration': contentTransliteration,
      'content_english': contentEnglish,
      'repeat_count': repeatCount,
      'source': source,
      'benefit': benefit,
      'display_order': displayOrder,
    };
  }
}
