import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pod_player_plus/pod_player_plus.dart';
import 'package:pod_player_plus/src/controllers/pod_getx_video_controller.dart';

void main() {
  tearDown(() async => Get.reset());

  testWidgets(
    'loads the current YouTube thumbnail and tolerates image failure',
    (tester) async {
      final controller = PodPlayerController(
        playVideoFrom: PlayVideoFrom.youtube(
          'https://www.youtube.com/watch?v=0jSgcE-sxeo',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: PodVideoPlayer(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        _thumbnail('https://img.youtube.com/vi/0jSgcE-sxeo/hqdefault.jpg'),
        findsOneWidget,
      );
      // Widget tests reject HTTP images. An unavailable automatic thumbnail
      // should leave the loading UI usable without surfacing an image exception.
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final internal = Get.find<PodGetXVideoController>(tag: controller.getTag)
        ..config(
          playVideoFrom: PlayVideoFrom.youtube(
            'https://youtu.be/39pzq8SdnbU?t=15',
          ),
          playerConfig: const PodPlayerConfig(),
        );
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        _thumbnail('https://img.youtube.com/vi/0jSgcE-sxeo/hqdefault.jpg'),
        findsNothing,
      );
      expect(
        _thumbnail('https://img.youtube.com/vi/39pzq8SdnbU/hqdefault.jpg'),
        findsOneWidget,
      );

      internal.config(
        playVideoFrom: PlayVideoFrom.network('https://example.com/video.mp4'),
        playerConfig: const PodPlayerConfig(),
      );
      await tester.pump();
      expect(
        _thumbnail('https://img.youtube.com/vi/39pzq8SdnbU/hqdefault.jpg'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'an explicit thumbnail takes precedence over the YouTube thumbnail',
    (tester) async {
      final controller = PodPlayerController(
        playVideoFrom: PlayVideoFrom.youtube('0jSgcE-sxeo'),
      );
      final custom = DecorationImage(
        image: const NetworkImage('https://example.com/custom.jpg'),
        onError: (error, stackTrace) {},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PodVideoPlayer(controller: controller, videoThumbnail: custom),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(_thumbnail('https://example.com/custom.jpg'), findsOneWidget);
      expect(
        _thumbnail('https://img.youtube.com/vi/0jSgcE-sxeo/hqdefault.jpg'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await tester.pump();
    },
  );
}

Finder _thumbnail(String url) => find.byWidgetPredicate((widget) {
  if (widget is! DecoratedBox || widget.decoration is! BoxDecoration) {
    return false;
  }
  final image = (widget.decoration as BoxDecoration).image?.image;
  return image is NetworkImage && image.url == url;
});
