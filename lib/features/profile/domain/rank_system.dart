import 'package:flutter/material.dart';

enum Rank { recruit, soldier, warrior, knight, commander, legend }

class RankSystem {
  static const Map<Rank, int> thresholds = {
    Rank.recruit: 0,
    Rank.soldier: 3,
    Rank.warrior: 7,
    Rank.knight: 14,
    Rank.commander: 30,
    Rank.legend: 90,
  };

  static const Map<Rank, String> titles = {
    Rank.recruit: 'Recruit',
    Rank.soldier: 'Soldier',
    Rank.warrior: 'Warrior',
    Rank.knight: 'Knight',
    Rank.commander: 'Commander',
    Rank.legend: 'Legend',
  };

  static const Map<Rank, Color> colors = {
    Rank.recruit: Colors.grey,
    Rank.soldier: Color(0xFFCD7F32), // Bronze
    Rank.warrior: Color(0xFFC0C0C0), // Silver
    Rank.knight: Color(0xFFFFD700), // Gold
    Rank.commander: Color(0xFF00BFFF), // Deep Sky Blue
    Rank.legend: Color(0xFF800080), // Purple
  };

  static const Map<Rank, IconData> icons = {
    Rank.recruit: Icons.star_border,
    Rank.soldier: Icons.shield_outlined,
    Rank.warrior: Icons.security,
    Rank.knight: Icons.gpp_good,
    Rank.commander: Icons.military_tech,
    Rank.legend: Icons.workspace_premium,
  };

  static Rank getRank(int streakDays) {
    if (streakDays >= 90) return Rank.legend;
    if (streakDays >= 30) return Rank.commander;
    if (streakDays >= 14) return Rank.knight;
    if (streakDays >= 7) return Rank.warrior;
    if (streakDays >= 3) return Rank.soldier;
    return Rank.recruit;
  }

  static double getProgressToNextRank(int streakDays) {
    final currentRank = getRank(streakDays);
    if (currentRank == Rank.legend) return 1.0;

    final nextRank = Rank.values[currentRank.index + 1];
    final currentThreshold = thresholds[currentRank]!;
    final nextThreshold = thresholds[nextRank]!;

    return (streakDays - currentThreshold) / (nextThreshold - currentThreshold);
  }

  static int getDaysToNextRank(int streakDays) {
    final currentRank = getRank(streakDays);
    if (currentRank == Rank.legend) return 0;

    final nextRank = Rank.values[currentRank.index + 1];
    return thresholds[nextRank]! - streakDays;
  }
}
