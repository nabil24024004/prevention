import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:prevention/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocking/data/blocker_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBlockerActive = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final status = await ref.read(blockerRepositoryProvider).isVpnActive();
    if (mounted) setState(() => _isBlockerActive = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Browser Protection Toggle
          Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              secondary: Icon(
                Icons.security,
                color: _isBlockerActive
                    ? AppColors.secondary
                    : AppColors.primary,
              ),
              title: Text(
                'Browser Protection',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _isBlockerActive
                    ? 'Adult sites blocked'
                    : 'Protection disabled',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              value: _isBlockerActive,
              activeColor: AppColors.secondary,
              onChanged: (value) async {
                try {
                  if (value) {
                    await ref.read(blockerRepositoryProvider).startBlocking();
                  } else {
                    await ref.read(blockerRepositoryProvider).stopBlocking();
                  }
                  await Future.delayed(const Duration(milliseconds: 500));
                  await _loadSettings();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ),

          // Notifications Toggle
          Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              secondary: Icon(Icons.notifications, color: AppColors.primary),
              title: Text(
                'Daily Reminders',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Get reminded to check in',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              value: _notificationsEnabled,
              activeColor: AppColors.secondary,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Reminders enabled' : 'Reminders disabled',
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Sign Out
          Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'Sign Out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Log out of your account',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}
