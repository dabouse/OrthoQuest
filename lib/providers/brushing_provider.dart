import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class BrushingState {
  final bool isRunning;
  final Duration remaining;
  final Duration total;

  BrushingState({
    this.isRunning = false,
    this.remaining = const Duration(minutes: 2),
    this.total = const Duration(minutes: 2),
  });

  BrushingState copyWith({
    bool? isRunning,
    Duration? remaining,
    Duration? total,
  }) {
    return BrushingState(
      isRunning: isRunning ?? this.isRunning,
      remaining: remaining ?? this.remaining,
      total: total ?? this.total,
    );
  }

  double get progress {
    if (total.inSeconds == 0) return 0.0;
    return (1.0 - (remaining.inMilliseconds / total.inMilliseconds)).clamp(
      0.0,
      1.0,
    );
  }
}

final brushingProvider = NotifierProvider<BrushingNotifier, BrushingState>(
  BrushingNotifier.new,
);

class BrushingNotifier extends Notifier<BrushingState> {
  Timer? _ticker;
  DateTime? _lastTick;

  @override
  BrushingState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return BrushingState();
  }

  void setDuration(Duration duration) {
    if (!state.isRunning) {
      state = state.copyWith(total: duration, remaining: duration);
    }
  }

  void startTimer() {
    if (state.isRunning) return;

    _lastTick = DateTime.now();
    state = state.copyWith(isRunning: true);
    _startTicker();
  }

  void stopTimer() {
    if (!state.isRunning) return;

    _ticker?.cancel();
    state = state.copyWith(isRunning: false);
    _lastTick = null;
  }

  void resetTimer() {
    _ticker?.cancel();
    state = BrushingState(total: state.total, remaining: state.total);
    _lastTick = null;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!state.isRunning) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      if (_lastTick != null) {
        final elapsed = now.difference(_lastTick!);
        final newRemaining = state.remaining - elapsed;

        if (newRemaining.isNegative || newRemaining == Duration.zero) {
          timer.cancel();
          state = state.copyWith(isRunning: false, remaining: Duration.zero);
          _lastTick = null;
        } else {
          state = state.copyWith(remaining: newRemaining);
          _lastTick = now;
        }
      } else {
        _lastTick = now;
      }
    });
  }
}
