import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/partnership_repository.dart';
import '../data/models/partnership.dart';

/// Partnership settings screen
class PartnerSettingsScreen extends ConsumerStatefulWidget {
  final String partnershipId;

  const PartnerSettingsScreen({super.key, required this.partnershipId});

  @override
  ConsumerState<PartnerSettingsScreen> createState() =>
      _PartnerSettingsScreenState();
}

class _PartnerSettingsScreenState extends ConsumerState<PartnerSettingsScreen> {
  Partnership? _partnership;
  bool _loading = true;
  bool _saving = false;

  // Local state for toggles
  bool _notifyOnRelapse = true;
  bool _notifyOnMissedCheckin = true;
  bool _notifyOnStreakMilestone = true;
  bool _anonymousMode = false;

  @override
  void initState() {
    super.initState();
    _loadPartnership();
  }

  Future<void> _loadPartnership() async {
    final partnerships = await ref.read(activePartnershipsProvider.future);
    final found = partnerships
        .where((p) => p.id == widget.partnershipId)
        .firstOrNull;

    if (found != null) {
      setState(() {
        _partnership = found;
        _notifyOnRelapse = found.notifyOnRelapse;
        _notifyOnMissedCheckin = found.notifyOnMissedCheckin;
        _notifyOnStreakMilestone = found.notifyOnStreakMilestone;
        _anonymousMode = found.anonymousMode;
        _loading = false;
      });
    } else {
      if (mounted) context.pop();
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);

    try {
      await ref
          .read(partnershipRepositoryProvider)
          .updateSettings(
            partnershipId: widget.partnershipId,
            notifyOnRelapse: _notifyOnRelapse,
            notifyOnMissedCheckin: _notifyOnMissedCheckin,
            notifyOnStreakMilestone: _notifyOnStreakMilestone,
            anonymousMode: _anonymousMode,
          );

      ref.invalidate(activePartnershipsProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _endPartnership() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'End Partnership?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will disconnect you from this accountability partner. '
          'You can always reconnect later with a new invite.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Partnership'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(partnershipRepositoryProvider)
          .endPartnership(widget.partnershipId);
      ref.invalidate(activePartnershipsProvider);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Partner Settings'),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving ? null : _saveSettings,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(color: Color(0xFF4ECDC4)),
                    ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partner info
                  _buildPartnerHeader(),
                  const SizedBox(height: 32),

                  // Notification settings
                  const Text(
                    'Notification Preferences',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose what notifications your partner receives about your journey',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 20),

                  _buildToggleTile(
                    title: 'Relapse Notifications',
                    subtitle: 'Partner receives alert when you need support',
                    icon: Icons.warning_amber,
                    iconColor: Colors.orange,
                    value: _notifyOnRelapse,
                    onChanged: (v) => setState(() => _notifyOnRelapse = v),
                  ),

                  _buildToggleTile(
                    title: 'Missed Check-in',
                    subtitle: 'Alert when you miss daily check-in',
                    icon: Icons.schedule,
                    iconColor: Colors.amber,
                    value: _notifyOnMissedCheckin,
                    onChanged: (v) =>
                        setState(() => _notifyOnMissedCheckin = v),
                  ),

                  _buildToggleTile(
                    title: 'Streak Milestones',
                    subtitle: 'Celebrate achievements together',
                    icon: Icons.celebration,
                    iconColor: const Color(0xFF4ECDC4),
                    value: _notifyOnStreakMilestone,
                    onChanged: (v) =>
                        setState(() => _notifyOnStreakMilestone = v),
                  ),

                  const Divider(color: Color(0xFF2D2D44), height: 40),

                  // Privacy
                  const Text(
                    'Privacy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildToggleTile(
                    title: 'Anonymous Mode',
                    subtitle: 'Hide your name and streak from partner',
                    icon: Icons.visibility_off,
                    iconColor: Colors.purple,
                    value: _anonymousMode,
                    onChanged: (v) => setState(() => _anonymousMode = v),
                  ),

                  const SizedBox(height: 40),

                  // End partnership
                  Center(
                    child: TextButton.icon(
                      onPressed: _endPartnership,
                      icon: const Icon(Icons.link_off, color: Colors.red),
                      label: const Text(
                        'End Partnership',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPartnerHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
            backgroundImage: _partnership?.partnerAvatarUrl != null
                ? NetworkImage(_partnership!.partnerAvatarUrl!)
                : null,
            child: _partnership?.partnerAvatarUrl == null
                ? Text(
                    (_partnership?.partnerDisplayName ?? 'P')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF4ECDC4),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _anonymousMode
                      ? 'Anonymous Partner'
                      : _partnership?.partnerDisplayName ?? 'Partner',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Partners since ${_formatDate(_partnership?.acceptedAt)}',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF4ECDC4),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'recently';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }
}
