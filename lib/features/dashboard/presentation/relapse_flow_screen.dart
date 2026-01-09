import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prevention/core/theme/app_colors.dart';
import '../data/dashboard_repository.dart';
import '../../auth/data/user_repository.dart';
import '../../progress/presentation/progress_screen.dart';

class RelapseFlowScreen extends ConsumerStatefulWidget {
  const RelapseFlowScreen({super.key});

  @override
  ConsumerState<RelapseFlowScreen> createState() => _RelapseFlowScreenState();
}

class _RelapseFlowScreenState extends ConsumerState<RelapseFlowScreen> {
  int _currentStep = 0;
  String _trigger = '';
  final _reflectionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isReflectionValid = false;

  @override
  void initState() {
    super.initState();
    _reflectionController.addListener(() {
      setState(() {
        _isReflectionValid = _reflectionController.text.length > 10;
      });
    });
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  final List<String> _triggers = [
    'Boredom',
    'Stress',
    'Loneliness',
    'Late Night',
    'Social Media',
    'Other',
  ];

  Future<void> _submitRelapse() async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(dashboardRepositoryProvider)
          .logRelapse(
            trigger: _trigger,
            reflection: _reflectionController.text,
          );

      // Sync all progress related data
      ref.invalidate(userProfileStreamProvider);
      ref.invalidate(weeklyCheckInsProvider);
      ref.invalidate(weeklyRelapsesProvider);
      ref.invalidate(progressDataProvider);
      ref.invalidate(relapseHistoryProvider);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Accountability',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildShameStep();
      case 1:
        return _buildTriggerStep();
      case 2:
        return _buildReflectionStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildShameStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.error,
          size: 80,
        ),
        const SizedBox(height: 24),
        Text(
          'You have broken your promise today.',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          '"Indeed, Allah is with those who are patient." - Quran 2:153',
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Text(
          'Your streak has been reset to 0 days.\nBut the door of Tawbah is always open.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('I Understand'),
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What triggered this fall?',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _triggers.map((trigger) {
            final isSelected = _trigger == trigger;
            return ChoiceChip(
              label: Text(trigger),
              selected: isSelected,
              onSelected: (_) => setState(() => _trigger = trigger),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.background
                    : AppColors.textPrimary,
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _trigger.isNotEmpty
                ? () => setState(() => _currentStep = 2)
                : null,
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildReflectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reflect on what happened.',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This is mandatory to proceed.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _reflectionController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'What will you do differently next time?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isReflectionValid && !_isSubmitting
                ? _submitRelapse
                : null,
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit & Repent'),
          ),
        ),
      ],
    );
  }
}
