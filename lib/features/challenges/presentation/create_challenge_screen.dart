import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/challenges_repository.dart';
import '../data/models/challenge.dart';

/// Screen for creating a new community challenge
class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController(text: '7');

  ChallengeType _selectedType = ChallengeType.streak;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _targetUnit = 'days';
  bool _isPublic = true;
  bool _isLoading = false;

  static const _accentColor = Color(0xFF4ECDC4);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Challenge Type Selection
            _buildSectionLabel('Challenge Type'),
            const SizedBox(height: 12),
            _buildTypeSelector(),

            const SizedBox(height: 24),

            // Title
            _buildSectionLabel('Title'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _titleController,
              hint: 'e.g., 7-Day Streak Challenge',
              validator: (v) =>
                  v?.isEmpty == true ? 'Please enter a title' : null,
            ),

            const SizedBox(height: 24),

            // Description
            _buildSectionLabel('Description'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Describe the challenge...',
              maxLines: 3,
              validator: (v) =>
                  v?.isEmpty == true ? 'Please enter a description' : null,
            ),

            const SizedBox(height: 24),

            // Goal
            _buildSectionLabel('Goal'),
            const SizedBox(height: 12),
            _buildGoalRow(),

            const SizedBox(height: 24),

            // Duration
            _buildSectionLabel('Duration'),
            const SizedBox(height: 12),
            _buildDateRow(),

            const SizedBox(height: 24),

            // Visibility
            _buildVisibilityToggle(),

            const SizedBox(height: 32),

            // Create Button
            _buildCreateButton(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ChallengeType.values.map((type) {
        final isSelected = type == _selectedType;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = type;
              // Update target unit based on type
              switch (type) {
                case ChallengeType.streak:
                  _targetUnit = 'days';
                  break;
                case ChallengeType.dhikr:
                  _targetUnit = 'count';
                  break;
                case ChallengeType.quran:
                  _targetUnit = 'pages';
                  break;
                case ChallengeType.custom:
                  _targetUnit = 'times';
                  break;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? _accentColor.withValues(alpha: 0.2)
                  : const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _accentColor : Colors.white10,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(type.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  type.displayName,
                  style: TextStyle(
                    color: isSelected ? _accentColor : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildGoalRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _targetController,
            hint: '7',
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v?.isEmpty == true) return 'Required';
              if (int.tryParse(v!) == null) return 'Invalid number';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            _targetUnit,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDateCard(
            label: 'Start',
            date: _startDate,
            onTap: () => _pickDate(isStart: true),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.arrow_forward, color: Colors.white38),
        ),
        Expanded(
          child: _buildDateCard(
            label: 'End',
            date: _endDate,
            onTap: () => _pickDate(isStart: false),
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('MMM d');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(date),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart ? DateTime.now() : _startDate;
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accentColor,
              surface: Color(0xFF1A1A2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(_isPublic ? Icons.public : Icons.lock, color: _accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Public Challenge' : 'Private Challenge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isPublic
                      ? 'Anyone can discover and join'
                      : 'Only people you invite can join',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
            activeThumbColor: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createChallenge,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: _accentColor.withValues(alpha: 0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Create Challenge',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(challengesRepositoryProvider)
          .createChallenge(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            type: _selectedType,
            startDate: _startDate,
            endDate: _endDate,
            targetValue: int.parse(_targetController.text),
            targetUnit: _targetUnit,
            isPublic: _isPublic,
          );

      if (mounted) {
        ref.invalidate(activeChallengesProvider);
        ref.invalidate(myChallengesProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Challenge created successfully!'),
            backgroundColor: _accentColor,
          ),
        );

        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating challenge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
