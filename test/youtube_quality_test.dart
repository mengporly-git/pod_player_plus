import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pod_player_plus/src/utils/video_apis.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test('keeps fallback HD video with audio on ${platform.name}', () async {
      debugDefaultTargetPlatformOverride = platform;
      var calls = 0;
      final urls = await VideoApis.loadYoutubeQualityUrls((clients) async {
        calls++;
        if (clients != null) throw StateError('Primary client blocked');
        return _manifest();
      });

      expect(calls, 2);
      expect(urls.map((url) => url.quality), containsAll([720, 1080]));
      expect(
        urls.every((url) => url.audioUrl == 'https://example.com/audio'),
        isTrue,
      );
    });
  }

  test('retries when primary manifest contains only muxed streams', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var calls = 0;
    final urls = await VideoApis.loadYoutubeQualityUrls((clients) async {
      calls++;
      return _manifest(adaptive: clients == null);
    });
    expect(calls, 2);
    expect(urls.map((url) => url.quality), contains(1080));
  });

  test('uses primary HD streams without a second request', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var calls = 0;
    final urls = await VideoApis.loadYoutubeQualityUrls((clients) async {
      calls++;
      return _manifest();
    });
    expect(calls, 1);
    expect(urls.map((url) => url.quality), contains(1080));
  });

  test('uses muxed streams when separate audio is unavailable', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final urls = await VideoApis.loadYoutubeQualityUrls(
      (_) async => _manifest(audio: false),
    );
    expect(urls.single.quality, 360);
    expect(urls.single.audioUrl, isNull);
  });

  test('retains muxed playback on unsupported platforms', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final urls = await VideoApis.loadYoutubeQualityUrls((clients) async {
      expect(clients, isNull);
      return _manifest();
    });
    expect(urls.single.quality, 360);
    expect(urls.single.audioUrl, isNull);
  });

  test('keeps playable primary streams if fallback fails', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final urls = await VideoApis.loadYoutubeQualityUrls((clients) async {
      if (clients == null) throw StateError('Fallback blocked');
      return _manifest(adaptive: false);
    });
    expect(urls.single.quality, 360);
    expect(urls.single.audioUrl, isNull);
  });

  test(
    'filters blocked HD streams and keeps a playable native fallback',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final urls = await VideoApis.loadYoutubeQualityUrls(
        (_) async => _manifest(),
        isPlayable: (url) async => url.audioUrl == null,
      );
      expect(urls.single.quality, 360);
      expect(urls.single.audioUrl, isNull);
    },
  );

  test('rejects preview-only streams when the end range is blocked', () async {
    final ranges = <String?>[];
    final client = MockClient((request) async {
      final range = request.headers['range'];
      ranges.add(range);
      return http.Response(
        range == null ? 'preview' : '',
        range == null ? 200 : 403,
      );
    });
    addTearDown(client.close);
    expect(
      await VideoApis.validateYoutubeStream(
        'https://example.com/video?clen=10000',
        client,
      ),
      isFalse,
    );
    expect(ranges, [null, 'bytes=8976-9999']);
  });

  test(
    'accepts a stream that serves native loading and its end range',
    () async {
      final client = MockClient(
        (request) async => http.Response(
          'media',
          request.headers.containsKey('range') ? 206 : 200,
        ),
      );
      addTearDown(client.close);
      expect(
        await VideoApis.validateYoutubeStream(
          'https://example.com/video?clen=10000',
          client,
        ),
        isTrue,
      );
    },
  );

  test('rejects an initial HTTP 403 without probing again', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return http.Response('', 403);
    });
    addTearDown(client.close);
    expect(
      await VideoApis.validateYoutubeStream(
        'https://example.com/video?clen=10000',
        client,
      ),
      isFalse,
    );
    expect(calls, 1);
  });

  test('reports failure when both clients fail', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await expectLater(
      VideoApis.loadYoutubeQualityUrls(
        (_) async => throw StateError('Blocked'),
      ),
      throwsStateError,
    );
  });
}

StreamManifest _manifest({bool adaptive = true, bool audio = true}) {
  final base = <String, dynamic>{
    'videoId': {'value': '39pzq8SdnbU'},
    'tag': 18,
    'url': 'https://example.com/muxed',
    'container': {'name': 'mp4'},
    'size': {'totalBytes': 1000},
    'bitrate': {'bitsPerSecond': 1000000},
    'audioCodec': 'mp4a.40.2',
    'videoCodec': 'avc1.640028',
    'qualityLabel': '360p',
    'videoQuality': 'medium360',
    'videoResolution': {'width': 640, 'height': 360},
    'framerate': {'framesPerSecond': 30},
    'fragments': <dynamic>[],
    'codec': 'video/mp4',
  };
  return StreamManifest([
    MuxedStreamInfo.fromJson(base),
    if (adaptive) ...[
      for (final quality in [720, 1080])
        VideoOnlyStreamInfo.fromJson({
          ...base,
          'tag': quality,
          'url': 'https://example.com/video-$quality',
          'qualityLabel': '${quality}p60',
          'videoQuality': 'high$quality',
          'videoResolution': {'width': quality * 16 ~/ 9, 'height': quality},
          'framerate': {'framesPerSecond': 60},
        }),
      if (audio)
        AudioOnlyStreamInfo.fromJson({
          ...base,
          'tag': 140,
          'url': 'https://example.com/audio',
          'codec': 'audio/mp4',
        }),
    ],
  ]);
}
