import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pod_player_plus/pod_player_plus.dart';
import 'package:pod_player_plus/src/utils/youtube_duration.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('uses precise stream duration for doubled iOS metadata', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final controller = _controller(
      '244.249',
      const Duration(milliseconds: 488500),
    );
    expect(correctYoutubeDuration(controller), isTrue);
    expect(controller.value.duration, const Duration(milliseconds: 244249));
    expect(controller.value.position, const Duration(seconds: 120));
    expect(correctYoutubeDuration(controller), isFalse);
  });

  test('preserves correct duration and Android metadata', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final correct = _controller(
      '244.249',
      const Duration(milliseconds: 244249),
    );
    expect(correctYoutubeDuration(correct), isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final android = _controller(
      '244.249',
      const Duration(milliseconds: 488500),
    );
    expect(correctYoutubeDuration(android), isFalse);
    expect(android.value.duration, const Duration(milliseconds: 488500));
  });

  test('keeps native duration when stream metadata is missing or invalid', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    for (final duration in ['', 'invalid', 'NaN', 'Infinity', '0', '-1']) {
      final controller = _controller(duration, const Duration(seconds: 488));
      expect(correctYoutubeDuration(controller), isFalse);
      expect(controller.value.duration, const Duration(seconds: 488));
    }
  });
}

VideoPlayerController _controller(String duration, Duration nativeDuration) =>
    VideoPlayerController.networkUrl(
        Uri.https('example.com', '/video', {'dur': duration}),
      )
      ..value = VideoPlayerValue(
        duration: nativeDuration,
        position: const Duration(seconds: 120),
        isInitialized: true,
      );
