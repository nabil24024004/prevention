import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/partnership_repository.dart';
import '../../data/models/partnership.dart';

/// Compact widget showing accountability partner status for dashboard
class AccountabilityWidget extends ConsumerWidget {
  const AccountabilityWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnershipsAsync = ref.watch(activePartnershipsProvider);
    final notificationsAsync = ref.watch(partnerNotificationsProvider);

    return GestureDetector(
      onTap: () => context.push('/accountability'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4ECDC4).withValues(alpha: 0.15),
              const Color(0xFF1A1A2E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
          ),
        ),
        child: partnershipsAsync.when(
          data: (partnerships) => _buildContent(
            context,
            partnerships,
            notificationsAsync.valueOrNull?.length ?? 0,
          ),
          loading: () => const _LoadingState(),
          error: (_, _) => const _ErrorState(),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Partnership> partnerships,
    int unreadCount,
  ) {
    if (partnerships.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Color(0xFF4ECDC4),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Accountability',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Partner avatars stack
        Row(
          children: [
            _buildAvatarStack(partnerships),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${partnerships.length} partner${partnerships.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Supporting each other',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarStack(List<Partnership> partnerships) {
    final displayCount = partnerships.length > 3 ? 3 : partnerships.length;

    return SizedBox(
      width: 20.0 + (displayCount * 24.0),
      height: 36,
      child: Stack(
        children: List.generate(displayCount, (index) {
          final partnership = partnerships[index];
          return Positioned(
            left: index * 20.0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF2D2D44),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                backgroundImage: partnership.partnerAvatarUrl != null
                    ? NetworkImage(partnership.partnerAvatarUrl!)
                    : null,
                child: partnership.partnerAvatarUrl == null
                    ? Text(
                        (partnership.partnerDisplayName ?? 'P')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF4ECDC4),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_add,
            color: Color(0xFF4ECDC4),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find an Accountability Partner',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect with someone for mutual support',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.white54),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF4ECDC4),
          ),
        ),
        SizedBox(width: 12),
        Text('Loading partners...', style: TextStyle(color: Colors.white54)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red, size: 20),
        SizedBox(width: 12),
        Text(
          'Could not load partners',
          style: TextStyle(color: Colors.white54),
        ),
      ],
    );
  }
}
