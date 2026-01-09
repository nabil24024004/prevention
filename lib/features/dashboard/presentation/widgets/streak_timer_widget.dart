import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakTimerWidget extends StatefulWidget {
  final DateTime startDate;

  const StreakTimerWidget({super.key, required this.startDate});

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
    final hours = _duration.inHours % 24;
    final minutes = _duration.inMinutes % 60;
    final seconds = _duration.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
