import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prevention/core/theme/app_colors.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/data/user_model.dart';
import '../domain/rank_system.dart';
import '../../progress/presentation/widgets/calendar_widget.dart';
import '../../challenges/presentation/widgets/challenges_widget.dart';
import '../../challenges/presentation/badges_screen.dart';
import '../../challenges/data/challenges_repository.dart';
import '../../challenges/data/models/user_badge.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // 240 is roughly the threshold where standard header collapses
    if (_scrollController.hasClients &&
        _scrollController.offset > 200 &&
        !_isPinned) {
      setState(() => _isPinned = true);
    } else if (_scrollController.hasClients &&
        _scrollController.offset <= 200 &&
        _isPinned) {
      setState(() => _isPinned = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileStreamProvider);
    final myBadgesAsync = ref.watch(myBadgesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: userProfileAsync.when(
        data: (profile) => _buildProfile(context, profile, myBadgesAsync, ref),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'Offline',
                style: TextStyle(color: Colors.grey[400], fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect to internet to view profile',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    UserProfile profile,
    AsyncValue<List<UserBadge>> badgesAsync,
    WidgetRef ref,
  ) {
    final streak = profile.currentStreakDays;
    final rank = RankSystem.getRank(streak);
    final nextRankProgress = RankSystem.getProgressToNextRank(streak);
    final daysToNext = RankSystem.getDaysToNextRank(streak);
    final rankColor = RankSystem.colors[rank]!;
    final rankIcon = RankSystem.icons[rank]!;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          expandedHeight: 320.0,
          pinned: true,
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isPinned ? 1.0 : 0.0,
            child: Text(
              profile.username ?? 'Warrior',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          centerTitle: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E1E), Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar / Rank Badge
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: rankColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: rankColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: rankColor.withValues(alpha: 0.1),
                      child: Icon(rankIcon, size: 50, color: rankColor),
                    ),
                  ).animate().scale(
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    profile.username ?? 'Warrior',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    RankSystem.titles[rank]!,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: rankColor,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Rank Progress
                if (rank != Rank.legend) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Next Rank: ${RankSystem.titles[Rank.values[rank.index + 1]]}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$daysToNext days left',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: nextRankProgress,
                      backgroundColor: Colors.grey[900],
                      valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: 32),
                ],

                // Badges Section
                _buildBadgesSection(context, badgesAsync),
                const SizedBox(height: 32),

                // Active Challenges
                Text(
                  'Active Challenges',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const ChallengesWidget(),
                const SizedBox(height: 32),

                // Stats Grid
                Text(
                  'Statistics',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Current Streak',
                        '$streak Days',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Best Streak',
                        '${profile.bestStreakDays} Days',
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const CalendarWidget(),

                const SizedBox(height: 32),

                // Settings Section
                Text(
                  'Settings',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                _buildSettingsTile(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'App Settings',
                  subtitle: 'VPN, Notifications, Account',
                  onTap: () => context.push('/settings'),
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'About Prevention',
                  subtitle: 'Version 5.0 Stable release',
                  onTap: () => context.push('/about'),
                ),

                const SizedBox(height: 20),
                Center(
                  child: InkWell(
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) context.go('/welcome');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.error.withValues(alpha: 0.15),
                            AppColors.error.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Padding for bottom
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildBadgesSection(
    BuildContext context,
    AsyncValue<List<UserBadge>> badgesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BadgesScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: badgesAsync.when(
            data: (badges) {
              if (badges.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Center(
                    child: Text(
                      'No badges yet. Keep going!',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              final displayBadges = badges.take(5).toList();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: displayBadges.length,
                separatorBuilder: (ctx, index) => const SizedBox(width: 12),
                itemBuilder: (ctx, index) =>
                    BadgeCard(badge: displayBadges[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const SizedBox(),
          ),
        ),
      ],
    );
  }
}
