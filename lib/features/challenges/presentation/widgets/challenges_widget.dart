import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/challenges_repository.dart';

/// Compact widget for dashboard showing active challenges
class ChallengesWidget extends ConsumerWidget {
  const ChallengesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myChallenges = ref.watch(myChallengesProvider);

    return GestureDetector(
      onTap: () => context.push('/challenges'),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF2D2D44).withValues(alpha: 0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('🏆', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'Challenges',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 16),
            myChallenges.when(
              loading: () => const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4ECDC4),
                  ),
                ),
              ),
              error: (_, _) => Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white38, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Tap to browse challenges',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              data: (challenges) {
                if (challenges.isEmpty) {
                  return Row(
                    children: [
                      Icon(
                        Icons.sports_score,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Join a challenge to compete!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                }

                // Show first challenge summary
                final challenge = challenges.first;
                final progress = challenge['my_progress'] as int? ?? 0;
                final target = challenge['target_value'] as int? ?? 1;
                final title = challenge['title'] as String? ?? 'Challenge';
                final percent = (progress / target).clamp(0.0, 1.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$progress / $target',
                          style: const TextStyle(
                            color: Color(0xFF4ECDC4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 6,
                        backgroundColor: const Color(0xFF2D2D44),
                        valueColor: AlwaysStoppedAnimation(
                          percent >= 1.0
                              ? Colors.green
                              : const Color(0xFF4ECDC4),
                        ),
                      ),
                    ),
                    if (challenges.length > 1) ...[
                      const SizedBox(height: 8),
                      Text(
                        '+${challenges.length - 1} more challenge${challenges.length > 2 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
