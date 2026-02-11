import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../spiritual/data/spiritual_repository.dart';

/// State for the reading session
class QuranReadingState {
  final DateTime? startTime;
  final int pagesRead;

  const QuranReadingState({this.startTime, this.pagesRead = 0});

  QuranReadingState copyWith({DateTime? startTime, int? pagesRead}) {
    return QuranReadingState(
      startTime: startTime ?? this.startTime,
      pagesRead: pagesRead ?? this.pagesRead,
    );
  }
}

/// Controller to track Quran reading time and sync with Spiritual/Challenges
class QuranReadingSession extends StateNotifier<QuranReadingState> {
  final Ref ref;

  QuranReadingSession(this.ref) : super(const QuranReadingState());

  /// Start tracking time
  void startSession() {
    state = state.copyWith(startTime: DateTime.now());
  }

  /// Manually log a page read (optional, for explicit "Done" button)
  void logPage() {
    state = state.copyWith(pagesRead: state.pagesRead + 1);
  }

  /// End session and sync to repository
  Future<void> endSession() async {
    if (state.startTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(state.startTime!);
    final minutes = duration.inMinutes;

    // Only log if meaningful time spent (e.g. > 1 minute) or pages read > 0
    if (minutes >= 1 || state.pagesRead > 0) {
      // Using the Notifier method for optimistic updates
      await ref
          .read(todaysSpiritualLogProvider.notifier)
          .updateQuranReading(
            pages: state.pagesRead > 0 ? state.pagesRead : null,
            minutes: minutes > 0 ? minutes : null,
          );
    }

    // Reset state
    state = const QuranReadingState();
  }
}

final quranReadingSessionProvider =
    StateNotifierProvider<QuranReadingSession, QuranReadingState>((ref) {
      return QuranReadingSession(ref);
    });
