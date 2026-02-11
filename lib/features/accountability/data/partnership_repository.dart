import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/partnership.dart';
import 'models/partner_notification.dart';

/// Repository for accountability partner operations
class PartnershipRepository {
  final SupabaseClient _client;

  PartnershipRepository(this._client);

  /// Get the current user's ID
  String? get _userId => _client.auth.currentUser?.id;

  // ========================================
  // PARTNERSHIP OPERATIONS
  // ========================================

  /// Create a new partnership invite and return the invite code
  Future<String> createInvite() async {
    final response = await _client.rpc('create_partnership_invite');

    // Fetch the created partnership to get the invite code
    final partnership = await _client
        .from('partnerships')
        .select('invite_code')
        .eq('id', response)
        .single();

    return partnership['invite_code'] as String;
  }

  /// Accept a partnership invite using the code
  Future<bool> acceptInvite(String inviteCode) async {
    final response = await _client.rpc(
      'accept_partnership_invite',
      params: {'p_invite_code': inviteCode.toUpperCase()},
    );

    return response['success'] == true;
  }

  /// Get all active partnerships for the current user
  Future<List<Partnership>> getActivePartnerships() async {
    final response = await _client
        .from('partnerships')
        .select('''
          *,
          partner:partner_id(id, display_name, avatar_url, current_streak),
          inviter:user_id(id, display_name, avatar_url, current_streak)
        ''')
        .eq('status', 'active')
        .or('user_id.eq.$_userId,partner_id.eq.$_userId');

    return (response as List).map((json) {
      // Determine which user is the partner
      final isInviter = json['user_id'] == _userId;
      final partnerData = isInviter ? json['partner'] : json['inviter'];

      return Partnership(
        id: json['id'],
        userId: json['user_id'],
        partnerId: json['partner_id'],
        status: PartnershipStatusX.fromString(json['status']),
        inviteCode: json['invite_code'],
        notifyOnRelapse: json['notify_on_relapse'] ?? true,
        notifyOnMissedCheckin: json['notify_on_missed_checkin'] ?? true,
        notifyOnStreakMilestone: json['notify_on_streak_milestone'] ?? true,
        anonymousMode: json['anonymous_mode'] ?? false,
        partnerDisplayName: partnerData?['display_name'],
        partnerAvatarUrl: partnerData?['avatar_url'],
        partnerCurrentStreak: partnerData?['current_streak'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        acceptedAt: json['accepted_at'] != null
            ? DateTime.parse(json['accepted_at'])
            : null,
      );
    }).toList();
  }

  /// Get pending invites created by the user
  Future<List<Partnership>> getPendingInvites() async {
    final response = await _client
        .from('partnerships')
        .select()
        .eq('user_id', _userId!)
        .eq('status', 'pending')
        .isFilter('partner_id', null);

    return (response as List)
        .map(
          (json) => Partnership(
            id: json['id'],
            userId: json['user_id'],
            status: PartnershipStatus.pending,
            inviteCode: json['invite_code'],
            createdAt: DateTime.parse(json['created_at']),
          ),
        )
        .toList();
  }

  /// Update partnership notification settings
  Future<void> updateSettings({
    required String partnershipId,
    bool? notifyOnRelapse,
    bool? notifyOnMissedCheckin,
    bool? notifyOnStreakMilestone,
    bool? anonymousMode,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (notifyOnRelapse != null) updates['notify_on_relapse'] = notifyOnRelapse;
    if (notifyOnMissedCheckin != null) {
      updates['notify_on_missed_checkin'] = notifyOnMissedCheckin;
    }
    if (notifyOnStreakMilestone != null) {
      updates['notify_on_streak_milestone'] = notifyOnStreakMilestone;
    }
    if (anonymousMode != null) updates['anonymous_mode'] = anonymousMode;

    await _client.from('partnerships').update(updates).eq('id', partnershipId);
  }

  /// End a partnership
  Future<bool> endPartnership(String partnershipId) async {
    final response = await _client.rpc(
      'end_partnership',
      params: {'p_partnership_id': partnershipId},
    );
    return response == true;
  }

  /// Delete a pending invite
  Future<void> deleteInvite(String partnershipId) async {
    await _client
        .from('partnerships')
        .delete()
        .eq('id', partnershipId)
        .eq('user_id', _userId!)
        .eq('status', 'pending');
  }

  // ========================================
  // NOTIFICATION OPERATIONS
  // ========================================

  /// Get unread notifications for the current user
  Future<List<PartnerNotification>> getUnreadNotifications() async {
    final response = await _client
        .from('partner_notifications')
        .select('''
          *,
          sender:sender_id(display_name, avatar_url)
        ''')
        .eq('recipient_id', _userId!)
        .isFilter('read_at', null)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (json) => PartnerNotification(
            id: json['id'],
            partnershipId: json['partnership_id'],
            senderId: json['sender_id'],
            recipientId: json['recipient_id'],
            type: PartnerNotificationTypeX.fromString(json['type']),
            title: json['title'],
            message: json['message'],
            metadata: json['metadata'] ?? {},
            readAt: json['read_at'] != null
                ? DateTime.parse(json['read_at'])
                : null,
            createdAt: DateTime.parse(json['created_at']),
            senderDisplayName: json['sender']?['display_name'],
            senderAvatarUrl: json['sender']?['avatar_url'],
          ),
        )
        .toList();
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('partner_notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _client
        .from('partner_notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('recipient_id', _userId!)
        .isFilter('read_at', null);
  }

  /// Send an encouragement message to a partner
  Future<void> sendEncouragement({
    required String partnershipId,
    required String recipientId,
    required String message,
  }) async {
    await _client.from('partner_notifications').insert({
      'partnership_id': partnershipId,
      'sender_id': _userId!,
      'recipient_id': recipientId,
      'type': 'encouragement',
      'title': 'Encouragement',
      'message': message,
    });
  }

  /// Notify partner of an event (used internally by app)
  Future<void> notifyPartner({
    required String eventType,
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.rpc(
      'notify_partner',
      params: {
        'p_event_type': eventType,
        'p_title': title,
        'p_message': message,
        'p_metadata': metadata ?? {},
      },
    );
  }
}

/// Provider for PartnershipRepository
final partnershipRepositoryProvider = Provider<PartnershipRepository>((ref) {
  return PartnershipRepository(Supabase.instance.client);
});

/// Provider for active partnerships
final activePartnershipsProvider = FutureProvider<List<Partnership>>((ref) {
  return ref.watch(partnershipRepositoryProvider).getActivePartnerships();
});

/// Provider for unread notifications
final partnerNotificationsProvider = FutureProvider<List<PartnerNotification>>((
  ref,
) {
  return ref.watch(partnershipRepositoryProvider).getUnreadNotifications();
});

/// Provider for pending invites
final pendingInvitesProvider = FutureProvider<List<Partnership>>((ref) {
  return ref.watch(partnershipRepositoryProvider).getPendingInvites();
});
