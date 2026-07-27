import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/vimeo_models.dart';

class _YoutubeManifestResult {
  const _YoutubeManifestResult({
    required this.manifest,
    required this.useMuxedOnly,
  });

  final StreamManifest manifest;
  final bool useMuxedOnly;
}

String podErrorString(String val) {
  return '*\n------error------\n\n$val\n\n------end------\n*';
}

class VideoApis {
  static Future<Response> _makeRequestHash(String videoId, String? hash) {
    if (hash == null) {
      return http.get(
        Uri.parse('https://player.vimeo.com/video/$videoId/config'),
      );
    } else {
      return http.get(
        Uri.parse('https://player.vimeo.com/video/$videoId/config?h=$hash'),
      );
    }
  }

  static Future<List<VideoQalityUrls>?> getVimeoVideoQualityUrls(
    String videoId,
    String? hash,
  ) async {
    try {
      final response = await _makeRequestHash(videoId, hash);
      return parseVimeoConfigResponse(response);
    } catch (error) {
      if (error.toString().contains('XMLHttpRequest')) {
        log(
          podErrorString(
            '(INFO) To play vimeo video in WEB, Please enable CORS in your browser',
          ),
        );
      }
      debugPrint('===== VIMEO API ERROR: $error ==========');
      rethrow;
    }
  }

  @visibleForTesting
  static List<VideoQalityUrls> parseVimeoConfigResponse(Response response) {
    final responseJson = _decodeVimeoResponse(
      response,
      endpointName: 'player configuration',
    );
    final request = _asStringMap(responseJson['request']);
    final files = _asStringMap(request?['files']);
    if (files == null) {
      throw const VimeoApiException(
        message: 'Vimeo did not return playback files for this video.',
      );
    }

    final progressiveUrls = _parseVimeoProgressiveUrls(files['progressive']);
    if (progressiveUrls.isNotEmpty) {
      return progressiveUrls;
    }

    final fallbackUrl = _getVimeoAdaptiveFallback(files);
    if (fallbackUrl != null) {
      return [
        VideoQalityUrls(
          quality: 720,
          url: fallbackUrl,
        ),
      ];
    }

    throw const VimeoApiException(
      message:
          'No compatible progressive, HLS, or DASH playback URL was returned.',
    );
  }

  static List<VideoQalityUrls> _parseVimeoProgressiveUrls(Object? rawUrls) {
    if (rawUrls is! List) return [];

    final urlsByQuality = <int, String>{};
    for (final rawUrl in rawUrls) {
      final item = _asStringMap(rawUrl);
      final url = item?['url'];
      final quality = _parseQuality(item?['quality']);
      if (url is String && url.isNotEmpty && quality != null) {
        urlsByQuality[quality] = url;
      }
    }

    return urlsByQuality.entries
        .map(
          (entry) => VideoQalityUrls(
            quality: entry.key,
            url: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.quality.compareTo(b.quality));
  }

  static String? _getVimeoAdaptiveFallback(Map<String, dynamic> files) {
    for (final formatName in const ['hls', 'dash']) {
      final format = _asStringMap(files[formatName]);
      final defaultCdn = format?['default_cdn'];
      final cdns = _asStringMap(format?['cdns']);
      final cdn = _asStringMap(cdns?[defaultCdn]);
      final url = cdn?['url'];
      if (url is String && url.isNotEmpty) return url;
    }
    return null;
  }

  static Future<List<VideoQalityUrls>?> getVimeoPrivateVideoQualityUrls(
    String videoId,
    Map<String, String> httpHeader,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.vimeo.com/videos/$videoId'),
        headers: httpHeader,
      );
      final responseJson = _decodeVimeoResponse(
        response,
        endpointName: 'Vimeo API',
      );
      final jsonData = (responseJson['files'] as List<dynamic>?) ?? [];

      final List<VideoQalityUrls> list = [];
      for (int i = 0; i < jsonData.length; i++) {
        final String quality =
            (jsonData[i]['rendition'] as String?)?.split('p').first ?? '0';
        final int? number = int.tryParse(quality);
        if (number != null && number != 0) {
          list.add(
            VideoQalityUrls(
              quality: number,
              url: jsonData[i]['link'] as String,
            ),
          );
        }
      }
      return list;
    } catch (error) {
      if (error.toString().contains('XMLHttpRequest')) {
        log(
          podErrorString(
            '(INFO) To play vimeo video in WEB, Please enable CORS in your browser',
          ),
        );
      }
      debugPrint('===== VIMEO API ERROR: $error ==========');
      rethrow;
    }
  }

  static Map<String, dynamic> _decodeVimeoResponse(
    Response response, {
    required String endpointName,
  }) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (!isSuccess) {
      final blockedIp = response.headers['x-banned-ip'];
      final apiError = _tryDecodeJsonMap(response.body);
      final apiMessage =
          apiError?['developer_message'] ?? apiError?['error'] ?? '';
      final message = blockedIp == null
          ? '$endpointName request failed'
                '${apiMessage is String && apiMessage.isNotEmpty ? ': $apiMessage' : '.'}'
          : 'Vimeo blocked playback requests from this network IP '
                '($blockedIp). Try another network or use the authenticated '
                'Vimeo API.';
      throw VimeoApiException(
        message: message,
        statusCode: response.statusCode,
      );
    }

    final responseJson = _tryDecodeJsonMap(response.body);
    if (responseJson == null) {
      throw VimeoApiException(
        message:
            '$endpointName returned ${response.headers['content-type'] ?? 'a non-JSON response'} instead of JSON.',
        statusCode: response.statusCode,
      );
    }
    return responseJson;
  }

  static Map<String, dynamic>? _tryDecodeJsonMap(String body) {
    try {
      return _asStringMap(jsonDecode(body));
    } on FormatException {
      return null;
    }
  }

  static Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  static int? _parseQuality(Object? value) {
    final match = RegExp(r'\d+').firstMatch(value?.toString() ?? '');
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  static Future<List<VideoQalityUrls>?> getYoutubeVideoQualityUrls(
    String youtubeIdOrUrl,
    bool live,
  ) async {
    final yt = YoutubeExplode();
    try {
      final urls = <VideoQalityUrls>[];
      if (live) {
        final url = await yt.videos.streamsClient.getHttpLiveStreamUrl(
          VideoId(youtubeIdOrUrl),
        );
        urls.add(
          VideoQalityUrls(
            quality: 360,
            url: url,
          ),
        );
      } else {
        final manifestResult = await _getYoutubeManifest(
          yt,
          VideoId(youtubeIdOrUrl),
        );
        final supportsAdaptivePlayback =
            _supportsAdaptiveYoutubePlayback && !manifestResult.useMuxedOnly;

        if (supportsAdaptivePlayback) {
          urls.addAll(
            _getAdaptiveYoutubeQualityUrls(manifestResult.manifest),
          );
        }

        if (urls.isEmpty) {
          urls.addAll(_getMuxedYoutubeQualityUrls(manifestResult.manifest));
        }
      }
      return urls;
    } catch (error) {
      if (error.toString().contains('XMLHttpRequest')) {
        log(
          podErrorString(
            '(INFO) To play youtube video in WEB, Please enable CORS in your browser',
          ),
        );
      }
      debugPrint('===== YOUTUBE API ERROR: $error ==========');
      rethrow;
    } finally {
      yt.close();
    }
  }

  static Future<_YoutubeManifestResult> _getYoutubeManifest(
    YoutubeExplode yt,
    VideoId videoId,
  ) async {
    if (_supportsAdaptiveYoutubePlayback) {
      try {
        final manifest = await yt.videos.streamsClient.getManifest(
          videoId,
          ytClients: const [YoutubeApiClient.androidVr],
        );
        return _YoutubeManifestResult(
          manifest: manifest,
          useMuxedOnly: false,
        );
      } on Object catch (error) {
        debugPrint(
          'Adaptive YouTube manifest failed; '
          'falling back to muxed playback: $error',
        );
      }
    }

    return _YoutubeManifestResult(
      manifest: await yt.videos.streamsClient.getManifest(videoId),
      useMuxedOnly: true,
    );
  }

  static bool get _supportsAdaptiveYoutubePlayback =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static List<VideoQalityUrls> _getAdaptiveYoutubeQualityUrls(
    StreamManifest manifest,
  ) {
    final videoStreams = manifest.videoOnly
        .where((stream) => stream.videoCodec.contains('avc'))
        .toList();
    final audioStreams =
        manifest.audioOnly
            .where((stream) => stream.audioCodec.contains('mp4a'))
            .toList()
          ..sort((a, b) => b.bitrate.compareTo(a.bitrate));

    if (videoStreams.isEmpty || audioStreams.isEmpty) {
      return [];
    }

    final audioUrl = audioStreams.first.url.toString();
    final streamsByQuality = <int, VideoOnlyStreamInfo>{};
    for (final stream in videoStreams) {
      final quality = _parseYoutubeQuality(stream.qualityLabel);
      if (quality == null) continue;

      final existing = streamsByQuality[quality];
      if (existing == null ||
          stream.framerate.compareTo(existing.framerate) > 0 ||
          (stream.framerate == existing.framerate &&
              stream.bitrate.compareTo(existing.bitrate) > 0)) {
        streamsByQuality[quality] = stream;
      }
    }

    return streamsByQuality.entries
        .map(
          (entry) => VideoQalityUrls(
            quality: entry.key,
            url: entry.value.url.toString(),
            audioUrl: audioUrl,
          ),
        )
        .toList();
  }

  static List<VideoQalityUrls> _getMuxedYoutubeQualityUrls(
    StreamManifest manifest,
  ) {
    final urlsByQuality = <int, MuxedStreamInfo>{};
    for (final stream in manifest.muxed) {
      if (!stream.videoCodec.contains('avc')) continue;
      final quality = _parseYoutubeQuality(stream.qualityLabel);
      if (quality == null) continue;

      final existing = urlsByQuality[quality];
      if (existing == null || stream.bitrate.compareTo(existing.bitrate) > 0) {
        urlsByQuality[quality] = stream;
      }
    }

    return urlsByQuality.entries
        .map(
          (entry) => VideoQalityUrls(
            quality: entry.key,
            url: entry.value.url.toString(),
          ),
        )
        .toList();
  }

  static int? _parseYoutubeQuality(String qualityLabel) {
    final match = RegExp(r'\d+').firstMatch(qualityLabel);
    return match == null ? null : int.tryParse(match.group(0)!);
  }
}
