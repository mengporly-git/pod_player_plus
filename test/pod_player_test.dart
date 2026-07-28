import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:pod_player_plus/pod_player_plus.dart';
import 'package:pod_player_plus/src/utils/video_apis.dart';

void main() {
  test('PodPlayerConfig defaults and copyWith remain stable', () {
    const config = PodPlayerConfig();
    final updated = config.copyWith(autoPlay: false);

    expect(config.autoPlay, isTrue);
    expect(updated.autoPlay, isFalse);
    expect(updated.videoQualityPriority, [1080, 720, 360]);
  });

  test('quality URL can describe a separate adaptive audio stream', () {
    final stream = VideoQalityUrls(
      quality: 1080,
      url: 'https://example.com/video.mp4',
      audioUrl: 'https://example.com/audio.m4a',
    );

    expect(stream.quality, 1080);
    expect(stream.audioUrl, isNotNull);
  });

  test('Vimeo HTML error response produces a useful exception', () {
    final response = Response(
      '<!DOCTYPE html><title>Sorry</title>',
      403,
      headers: {
        'content-type': 'text/html; charset=UTF-8',
        'x-banned-ip': '192.0.2.1',
      },
    );

    expect(
      () => VideoApis.parseVimeoConfigResponse(response),
      throwsA(
        isA<VimeoApiException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having(
              (error) => error.message,
              'message',
              contains('blocked playback requests'),
            ),
      ),
    );
  });

  test('Vimeo progressive streams are parsed into quality URLs', () {
    final response = Response(
      '''
      {
        "request": {
          "files": {
            "progressive": [
              {"quality": "360p", "url": "https://example.com/360.mp4"},
              {"quality": "1080p", "url": "https://example.com/1080.mp4"}
            ]
          }
        }
      }
      ''',
      200,
      headers: {'content-type': 'application/json'},
    );

    final urls = VideoApis.parseVimeoConfigResponse(response);

    expect(urls.map((url) => url.quality), [360, 1080]);
    expect(urls.last.url, 'https://example.com/1080.mp4');
  });
}
