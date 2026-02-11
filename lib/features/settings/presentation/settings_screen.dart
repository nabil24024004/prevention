import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:prevention/core/theme/app_colors.dart';
import 'package:prevention/core/services/notification_service.dart';
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
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final status = await ref.read(blockerRepositoryProvider).isVpnActive();
    final notificationsEnabled = await NotificationService()
        .areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _isBlockerActive = status;
        _notificationsEnabled = notificationsEnabled;
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _handleNotificationToggle(bool value) async {
    setState(() => _notificationsEnabled = value);
    await NotificationService().setNotificationsEnabled(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Reminders enabled' : 'Reminders disabled',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: value ? AppColors.secondary : AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    try {
      await NotificationService().showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test notification sent! Check your status bar.',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Settings',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _SettingsSection(
                    title: 'PROTECTION',
                    children: [
                      _SettingsTile(
                        icon: Icons.security_rounded,
                        title: 'Browser Protection',
                        subtitle: _isBlockerActive ? 'Active' : 'Disabled',
                        trailing: Switch(
                          value: _isBlockerActive,
                          activeThumbColor: AppColors.secondary,
                          activeTrackColor: AppColors.secondary.withValues(
                            alpha: 0.3,
                          ),
                          inactiveThumbColor: AppColors.textSecondary,
                          inactiveTrackColor: AppColors.surface,
                          onChanged: (value) async {
                            try {
                              if (value) {
                                await ref
                                    .read(blockerRepositoryProvider)
                                    .startBlocking();
                              } else {
                                await ref
                                    .read(blockerRepositoryProvider)
                                    .stopBlocking();
                              }
                              // Add a small delay for the VPN state to propagate usually
                              await Future.delayed(
                                const Duration(milliseconds: 500),
                              );
                              await _loadSettings();
                            } catch (e) {
                              if (context.mounted) {
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
                    ],
                  ),

                  const SizedBox(height: 24),

                  _SettingsSection(
                    title: 'NOTIFICATIONS',
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_active_rounded,
                        title: 'Daily Reminders',
                        subtitle: 'Get notified to check in',
                        trailing: _isLoadingNotifications
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Switch(
                                value: _notificationsEnabled,
                                activeThumbColor: AppColors.secondary,
                                activeTrackColor: AppColors.secondary
                                    .withValues(alpha: 0.3),
                                inactiveThumbColor: AppColors.textSecondary,
                                inactiveTrackColor: AppColors.surface,
                                onChanged: _handleNotificationToggle,
                              ),
                      ),
                      // _SettingsTile(
                      //   icon: Icons.send_rounded,
                      //   title: 'Test Notification',
                      //   subtitle: 'Send a test notification now',
                      //   onTap: _testNotification,
                      //   showArrow: true,
                      // ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _SettingsSection(
                    title: 'ACCOUNT',
                    children: [
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        titleColor: AppColors.error,
                        iconColor: AppColors.error,
                        // No subtitle for sign out usually
                        subtitle: '',
                        onTap: () async {
                          // Show confirmation dialog? Or just sign out.
                          // For now, keep it simple but maybe add a dialog later if needed.
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Text(
                    'Version 5.0.0',
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final widget = entry.value;
              final isLast = index == children.length - 1;

              return Column(
                children: [
                  widget,
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: AppColors.textSecondary.withValues(alpha: 0.1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;
  final bool showArrow;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: titleColor ?? AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            )
          : null,
      trailing:
          trailing ??
          (showArrow
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                )
              : null),
    );
  }
}
