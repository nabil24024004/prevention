import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakTimerWidget extends StatefulWidget {
  final DateTime startDate;
  final bool isPaused;

  const StreakTimerWidget({
    super.key,
    required this.startDate,
    this.isPaused = false,
  });

  @override
  State<StreakTimerWidget> createState() => _StreakTimerWidgetState();
}

class _StreakTimerWidgetState extends State<StreakTimerWidget> {
  late Timer _timer;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (widget.isPaused) {
      if (mounted) {
        setState(() {
          _duration = Duration.zero;
        });
      }
      return;
    }
    setState(() {
      _duration = DateTime.now().difference(widget.startDate);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPaused) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Text(
          '0h 0m 0s',
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    final hours = _duration.inHours % 24;
    final minutes = _duration.inMinutes % 60;
    final seconds = _duration.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        '${hours}h ${minutes}m ${seconds}s',
        style: GoogleFonts.outfit(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
