import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/spiritual_repository.dart';
import '../data/models/spiritual_log.dart';

/// Interactive dhikr counter screen with haptic feedback
class DhikrCounterScreen extends ConsumerStatefulWidget {
  const DhikrCounterScreen({super.key});

  @override
  ConsumerState<DhikrCounterScreen> createState() => _DhikrCounterScreenState();
}

class _DhikrCounterScreenState extends ConsumerState<DhikrCounterScreen>
    with SingleTickerProviderStateMixin {
  DhikrType _selectedDhikr = DhikrType.subhanallah;
  int _currentCount = 0;
  int _targetCount = 33;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<int> _targets = [33, 100, 500, 1000];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadCurrentCount();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentCount() async {
    final log = await ref.read(todaysSpiritualLogProvider.future);
    if (log != null && mounted) {
      setState(() {
        _currentCount = _getCountForType(log, _selectedDhikr);
      });
    }
  }

  int _getCountForType(SpiritualLog log, DhikrType type) {
    switch (type) {
      case DhikrType.subhanallah:
        return log.subhanallahCount;
      case DhikrType.alhamdulillah:
        return log.alhamdulillahCount;
      case DhikrType.allahuakbar:
        return log.allahuakbarCount;
      case DhikrType.istighfar:
        return log.istighfarCount;
      case DhikrType.salawat:
        return log.salawatCount;
      case DhikrType.custom:
        return log.customDhikrCount;
    }
  }

  Future<void> _incrementCount() async {
    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Visual feedback
    _pulseController.forward().then((_) => _pulseController.reverse());

    setState(() => _currentCount++);

    try {
      await ref
          .read(spiritualRepositoryProvider)
          .incrementDhikr(_selectedDhikr);

      // Check if target reached
      if (_currentCount == _targetCount) {
        _showTargetReached();
      }
    } catch (e) {
      // Revert on error
      setState(() => _currentCount--);
    }
  }

  void _showTargetReached() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'MashaAllah!',
              style: TextStyle(
                color: const Color(0xFF4ECDC4),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You completed $_targetCount ${_selectedDhikr.transliteration}',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(
                () => _targetCount =
                    _targets[(_targets.indexOf(_targetCount) + 1) %
                        _targets.length],
              );
            },
            child: const Text(
              'Continue',
              style: TextStyle(color: Color(0xFF4ECDC4)),
            ),
          ),
        ],
      ),
    );
  }

  void _resetCount() {
    HapticFeedback.lightImpact();
    setState(() => _currentCount = 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _targetCount > 0
        ? (_currentCount / _targetCount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Dhikr Counter'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Dhikr type selector
          _buildDhikrSelector(),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Arabic text
                  Text(
                    _selectedDhikr.arabicText,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 40,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedDhikr.meaning,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Counter button
                  GestureDetector(
                    onTap: _incrementCount,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      ),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                              const Color(0xFF1A1A2E),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFF4ECDC4),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$_currentCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFF2D2D44),
                            valueColor: AlwaysStoppedAnimation(
                              progress >= 1.0
                                  ? Colors.green
                                  : const Color(0xFF4ECDC4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_currentCount / $_targetCount',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildDhikrSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: DhikrType.values
              .where((t) => t != DhikrType.custom)
              .map((type) => _buildDhikrChip(type))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDhikrChip(DhikrType type) {
    final isSelected = _selectedDhikr == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          type.transliteration,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (_) async {
          setState(() {
            _selectedDhikr = type;
            _currentCount = 0;
          });
          await _loadCurrentCount();
        },
        backgroundColor: const Color(0xFF2D2D44),
        selectedColor: const Color(0xFF4ECDC4),
        checkmarkColor: Colors.black,
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Target selector
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Target: ',
                    style: TextStyle(color: Colors.white54),
                  ),
                  DropdownButton<int>(
                    value: _targetCount,
                    dropdownColor: const Color(0xFF2D2D44),
                    underline: const SizedBox(),
                    style: const TextStyle(
                      color: Color(0xFF4ECDC4),
                      fontWeight: FontWeight.bold,
                    ),
                    items: _targets
                        .map(
                          (t) => DropdownMenuItem(value: t, child: Text('$t')),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _targetCount = v!),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Reset button
          IconButton(
            onPressed: _resetCount,
            icon: const Icon(Icons.refresh, color: Colors.white54),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}
