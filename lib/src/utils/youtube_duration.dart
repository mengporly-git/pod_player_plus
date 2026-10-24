import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// AVFoundation can report twice the duration of YouTube's adaptive MP4s.
/// Use the stream's precise duration, without scaling its playback timestamps.
bool correctYoutubeDuration(VideoPlayerController controller) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;
  final seconds = double.tryParse(
    Uri.tryParse(controller.dataSource)?.queryParameters['dur'] ?? '',
  );
  if (seconds == null || !seconds.isFinite || seconds <= 0) return false;
  final duration = Duration(
    microseconds: (seconds * Duration.microsecondsPerSecond).round(),
  );
  final value = controller.value;
  if (!value.isInitialized ||
      (value.duration - duration).abs() <= const Duration(seconds: 1)) {
    return false;
  }
  // Correct the controller itself so labels, progress, public values, and
  // video_player's seek bounds and replay logic all use the same timeline.
  controller.value = value.copyWith(duration: duration);
  return true;
}
