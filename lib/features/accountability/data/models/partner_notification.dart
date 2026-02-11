/// Type of partner notification
enum PartnerNotificationType {
  relapse,
  missedCheckin,
  milestone,
  encouragement,
  partnershipRequest,
}

/// Represents a notification sent between accountability partners
class PartnerNotification {
  final String id;
  final String partnershipId;
  final String senderId;
  final String recipientId;
  final PartnerNotificationType type;
  final String? title;
  final String? message;
  final Map<String, dynamic> metadata;
  final DateTime? readAt;
  final DateTime createdAt;

  // Populated when fetching
  final String? senderDisplayName;
  final String? senderAvatarUrl;

  PartnerNotification({
    required this.id,
    required this.partnershipId,
    required this.senderId,
    required this.recipientId,
    required this.type,
    this.title,
    this.message,
    this.metadata = const {},
    this.readAt,
    required this.createdAt,
    this.senderDisplayName,
    this.senderAvatarUrl,
  });

  factory PartnerNotification.fromJson(Map<String, dynamic> json) {
    return PartnerNotification(
      id: json['id'] as String,
      partnershipId: json['partnership_id'] as String,
      senderId: json['sender_id'] as String,
      recipientId: json['recipient_id'] as String,
      type: PartnerNotificationTypeX.fromString(json['type'] as String),
      title: json['title'] as String?,
      message: json['message'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderDisplayName: json['sender_display_name'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnership_id': partnershipId,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'type': type.value,
      'title': title,
      'message': message,
      'metadata': metadata,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Extension for PartnerNotificationType serialization
extension PartnerNotificationTypeX on PartnerNotificationType {
  String get value {
    switch (this) {
      case PartnerNotificationType.relapse:
        return 'relapse';
      case PartnerNotificationType.missedCheckin:
        return 'missed_checkin';
      case PartnerNotificationType.milestone:
        return 'milestone';
      case PartnerNotificationType.encouragement:
        return 'encouragement';
      case PartnerNotificationType.partnershipRequest:
        return 'partnership_request';
    }
  }

  static PartnerNotificationType fromString(String value) {
    switch (value) {
      case 'relapse':
        return PartnerNotificationType.relapse;
      case 'missed_checkin':
        return PartnerNotificationType.missedCheckin;
      case 'milestone':
        return PartnerNotificationType.milestone;
      case 'encouragement':
        return PartnerNotificationType.encouragement;
      case 'partnership_request':
        return PartnerNotificationType.partnershipRequest;
      default:
        return PartnerNotificationType.encouragement;
    }
  }
}
