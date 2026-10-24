import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pod_player_plus/pod_player_plus.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plays native YouTube at 1080p and seeks beyond the opening', (
    tester,
  ) async {
    final controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.youtube(
        'https://www.youtube.com/watch?v=0jSgcE-sxeo',
      ),
      podPlayerConfig: const PodPlayerConfig(autoPlay: false),
    );
    Object? initializationError;
    final initialization = controller.initialise().catchError((Object error) {
      initializationError = error;
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PodVideoPlayer(controller: controller)),
      ),
    );
    try {
      for (
        var i = 0;
        i < 120 && !controller.isInitialised && initializationError == null;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(initializationError, isNull);
      expect(controller.isInitialised, isTrue);
      await initialization;
      await tester.pump();
      expect(find.byType(VideoPlayer), findsOneWidget);
      expect(controller.videoPlayerValue!.size.height, 1080);
      debugPrint(
        'Native video dimensions: ${controller.videoPlayerValue!.size}',
      );
      debugPrint(
        'Native duration: ${controller.videoPlayerValue!.duration}; '
        'Pod duration: ${controller.totalVideoLength}',
      );
      expect(controller.totalVideoLength.inSeconds, inInclusiveRange(243, 245));
      controller.play();
      for (
        var i = 0;
        i < 60 && controller.currentVideoPosition < const Duration(seconds: 2);
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(
        controller.videoPlayerValue!.hasError,
        isFalse,
        reason: controller.videoPlayerValue!.errorDescription,
      );
      expect(
        controller.currentVideoPosition,
        greaterThan(const Duration(seconds: 1)),
      );
      for (final seconds in [150, 230]) {
        await controller.videoSeekTo(Duration(seconds: seconds));
        for (
          var i = 0;
          i < 40 &&
              controller.currentVideoPosition < Duration(seconds: seconds + 2);
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        expect(
          controller.videoPlayerValue!.hasError,
          isFalse,
          reason: controller.videoPlayerValue!.errorDescription,
        );
        expect(
          controller.currentVideoPosition,
          greaterThan(Duration(seconds: seconds + 1)),
        );
      }
      controller.pause();
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.isVideoPlaying, isFalse);
      expect(controller.totalVideoLength.inSeconds, inInclusiveRange(243, 245));
      expect(
        controller.videoPlayerValue!.duration,
        controller.totalVideoLength,
      );

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('1080p'), findsOneWidget);
      await tester.tap(find.text('Quality'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('720p'), findsOneWidget);
      await tester.tap(find.text('720p'));
      for (
        var i = 0;
        i < 60 &&
            (controller.videoPlayerValue!.size.height != 720 ||
                controller.videoState == PodVideoState.loading);
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(controller.videoPlayerValue!.hasError, isFalse);
      expect(controller.videoPlayerValue!.size.height, 720);
      expect(
        controller.currentVideoPosition,
        greaterThan(const Duration(seconds: 229)),
      );
      expect(controller.isVideoPlaying, isFalse);
      expect(controller.totalVideoLength.inSeconds, inInclusiveRange(243, 245));
      expect(controller.videoState, PodVideoState.paused);
      // Finish at the real end, rather than playing through iOS's empty tail.
      await controller.videoSeekTo(
        controller.totalVideoLength - const Duration(seconds: 2),
      );
      controller.play();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (controller.videoPlayerValue!.isCompleted &&
            !controller.isVideoPlaying) {
          break;
        }
      }
      debugPrint('End value: ${controller.videoPlayerValue}');
      expect(controller.videoPlayerValue!.isCompleted, isTrue);
      expect(controller.isVideoPlaying, isFalse);
      expect(controller.isVideoBuffering, isFalse);
      expect(
        controller.videoPlayerValue!.position,
        controller.totalVideoLength,
      );

      await controller
          .videoSeekTo(
            controller.totalVideoLength + const Duration(seconds: 30),
          )
          .timeout(const Duration(seconds: 10));
      expect(
        controller.videoPlayerValue!.position,
        controller.totalVideoLength,
      );

      controller.play();
      await tester.pump(const Duration(seconds: 1));
      expect(controller.isVideoPlaying, isTrue);
      expect(
        controller.currentVideoPosition,
        lessThan(const Duration(seconds: 5)),
      );

      controller.pause();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Loop Video'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.isVideoLooping, isTrue);
      await controller.videoSeekTo(
        controller.totalVideoLength - const Duration(seconds: 2),
      );
      controller.play();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (controller.currentVideoPosition < const Duration(seconds: 5)) break;
      }
      expect(
        controller.currentVideoPosition,
        lessThan(const Duration(seconds: 5)),
      );
      expect(controller.isVideoPlaying, isTrue);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await tester.pump();
    }
  });
}
