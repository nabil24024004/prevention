import 'package:flutter/material.dart';

class AppColors {
  // Premium Dark Palette
  static const Color background = Color(0xFF0F1115); // Deep almost-black
  static const Color surface = Color(0xFF1A1D23); // Slightly lighter for cards
  static const Color primary = Color(0xFFFFD700); // Brighter Gold
  static const Color secondary = Color(0xFF64FFDA); // Brighter Teal
  static const Color error = Color(0xFFFF5252); // Brighter Red
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure White
  static const Color textSecondary = Color(0xFFE0E0E0); // Lighter Grey

  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFE0C097), Color(0xFFB89B72)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
