# Brushing Timer Implementation

This document outlines the implementation of the background-persistent brushing timer.

## Overview

The brushing timer has been refactored to use a global `BrushingProvider` instead of local widget state. This ensures the timer continues to run accurately even when:
1. The user navigates away from the brushing screen within the app.
2. The user puts the application into the background.

## Key Components

### 1. BrushingProvider (`lib/providers/brushing_provider.dart`)

- **State Management**: Uses `NotifierProvider` to manage `BrushingState`.
- **Background Persistence**: 
  - Instead of relying solely on `Timer.periodic` ticks (which pause in background), the provider calculates elapsed time using `DateTime.now().difference(_lastTick)`.
  - When the app resumes or the timer fires after a pause, the remaining time is updated based on the actual wall-clock time elapsed.
- **Lifecycle**: The provider is not `autoDispose`, meaning the timer state persists as long as the app is running.

### 2. BrushingScreen (`lib/ui/screens/brushing_screen.dart`)

- **UI Integration**: 
  - Subscribes to `brushingProvider` via `ref.watch` to update the UI (progress circle, animations).
  - Uses `ref.listen` to detect timer completion and trigger side effects (sound, confetti, dialog).
- **Initialization**: 
  - Checks if a timer is already running in `initState` before setting the duration from settings. This prevents resetting an active timer when re-entering the screen.
- **Dialog Styling**: 
  - The completion dialog has been updated with a solid dark background (`Color(0xFF1E1E2E)`) and neon borders/shadows for better visibility and aesthetics.
  - Spacing has been compacted to reduce "empty space" and improve the layout.

## Usage Flow

1. **Start**: User taps "Play" -> `provider.startTimer()`.
2. **Background**: User minimizes app. `DateTime` keeps ticking.
3. **Resume**: User re-opens app. Next `Timer` tick calculates large elapsed time and updates state instantly.
4. **Completion**: When remaining time <= 0, `ref.listen` fires `_completeSession()`, showing the success dialog and awarding XP.
