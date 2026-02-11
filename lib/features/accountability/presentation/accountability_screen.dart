import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/partnership_repository.dart';
import '../data/models/partnership.dart';
import '../data/models/partner_notification.dart';

/// Main accountability partners screen
class AccountabilityScreen extends ConsumerStatefulWidget {
  const AccountabilityScreen({super.key});

  @override
  ConsumerState<AccountabilityScreen> createState() =>
      _AccountabilityScreenState();
}

class _AccountabilityScreenState extends ConsumerState<AccountabilityScreen> {
  final _inviteCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _createInvite() async {
    try {
      final code = await ref.read(partnershipRepositoryProvider).createInvite();
      if (mounted) {
        _showInviteCodeDialog(code);
      }
    } catch (e) {
      _showError('Failed to create invite: $e');
    }
  }

  void _showInviteCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Share This Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Give this code to someone you trust to become accountability partners:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D44),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4ECDC4), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      color: Color(0xFF4ECDC4),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF4ECDC4)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This code expires in 7 days',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Done',
              style: TextStyle(color: Color(0xFF4ECDC4)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinWithCode() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty || code.length != 8) {
      _showError('Please enter a valid 8-character code');
      return;
    }

    setState(() => _isJoining = true);

    try {
      final success = await ref
          .read(partnershipRepositoryProvider)
          .acceptInvite(code);
      if (success) {
        _inviteCodeController.clear();
        ref.invalidate(activePartnershipsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Partnership created successfully!'),
              backgroundColor: Color(0xFF4ECDC4),
            ),
          );
        }
      } else {
        _showError('Invalid or expired invite code');
      }
    } catch (e) {
      _showError('Failed to join: $e');
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnershipsAsync = ref.watch(activePartnershipsProvider);
    final notificationsAsync = ref.watch(partnerNotificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Accountability Partners',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          notificationsAsync.when(
            data: (notifications) => notifications.isEmpty
                ? const SizedBox.shrink()
                : Badge(
                    label: Text('${notifications.length}'),
                    child: IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () => _showNotificationsSheet(notifications),
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header explanation
            _buildInfoCard(),
            const SizedBox(height: 24),

            // Join with code section
            _buildJoinSection(),
            const SizedBox(height: 24),

            // Active partnerships
            const Text(
              'Your Partners',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            partnershipsAsync.when(
              data: (partnerships) => partnerships.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: partnerships
                          .map((p) => _buildPartnerCard(p))
                          .toList(),
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
              ),
              error: (e, _) =>
                  Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createInvite,
        backgroundColor: const Color(0xFF4ECDC4),
        icon: const Icon(Icons.person_add, color: Colors.black),
        label: const Text(
          'Invite Partner',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4ECDC4).withValues(alpha: 0.2),
            const Color(0xFF2D2D44).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups,
                  color: Color(0xFF4ECDC4),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Strength in Brotherhood',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '"And cooperate in righteousness and piety." — Quran 5:2',
            style: TextStyle(
              color: Color(0xFF4ECDC4),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Connect with a trusted brother or sister who can support your journey. '
            'They will receive notifications when you need encouragement.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Have an invite code?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inviteCodeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  style: const TextStyle(color: Colors.white, letterSpacing: 2),
                  decoration: InputDecoration(
                    hintText: 'ABCD1234',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFF2D2D44),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isJoining ? null : _joinWithCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isJoining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Join',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No partners yet',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Invite someone or enter a code to connect',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(Partnership partnership) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D44)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
            backgroundImage: partnership.partnerAvatarUrl != null
                ? NetworkImage(partnership.partnerAvatarUrl!)
                : null,
            child: partnership.partnerAvatarUrl == null
                ? Text(
                    (partnership.partnerDisplayName ?? 'P')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF4ECDC4),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnership.anonymousMode
                      ? 'Anonymous Partner'
                      : partnership.partnerDisplayName ?? 'Partner',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (partnership.partnerCurrentStreak != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${partnership.partnerCurrentStreak} day streak',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Actions
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFF4ECDC4),
            ),
            onPressed: () => _showEncouragementDialog(partnership),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () =>
                context.push('/accountability/settings/${partnership.id}'),
          ),
        ],
      ),
    );
  }

  void _showEncouragementDialog(Partnership partnership) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Send Encouragement',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Write a supportive message...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: const Color(0xFF2D2D44),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _quickMessageChip('Stay strong! 💪', controller),
                _quickMessageChip('Proud of you! 🌟', controller),
                _quickMessageChip('Allah is with you 🤲', controller),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref
                    .read(partnershipRepositoryProvider)
                    .sendEncouragement(
                      partnershipId: partnership.id,
                      recipientId: partnership.partnerId!,
                      message: controller.text,
                    );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message sent! 💚')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
            ),
            child: const Text('Send', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _quickMessageChip(String text, TextEditingController controller) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: const Color(0xFF2D2D44),
      side: BorderSide.none,
      onPressed: () => controller.text = text,
    );
  }

  void _showNotificationsSheet(List<PartnerNotification> notifications) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Partner Updates',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(partnershipRepositoryProvider)
                        .markAllAsRead();
                    ref.invalidate(partnerNotificationsProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: Color(0xFF4ECDC4)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...notifications.map((n) => _buildNotificationTile(n)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(PartnerNotification notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case PartnerNotificationType.relapse:
        icon = Icons.warning_amber;
        color = Colors.orange;
        break;
      case PartnerNotificationType.missedCheckin:
        icon = Icons.schedule;
        color = Colors.amber;
        break;
      case PartnerNotificationType.milestone:
        icon = Icons.celebration;
        color = const Color(0xFF4ECDC4);
        break;
      case PartnerNotificationType.encouragement:
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      case PartnerNotificationType.partnershipRequest:
        icon = Icons.person_add;
        color = Colors.blue;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title ?? 'Notification',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (notification.message != null)
                  Text(
                    notification.message!,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
