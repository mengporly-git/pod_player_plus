import 'dart:io';

import '../../pod_player_plus.dart';

class PlayVideoFrom {
  final String? dataSource;
  final String? hash;
  final PodVideoPlayerType playerType;
  final VideoFormat? formatHint;
  final String? package;
  final File? file;
  final List<VideoQalityUrls>? videoQualityUrls;
  final Future<ClosedCaptionFile>? closedCaptionFile;
  final VideoPlayerOptions? videoPlayerOptions;
  final Map<String, String> httpHeaders;
  final bool live;

  const new _({
    required this.playerType,
    this.live = false,
    this.dataSource,
    this.hash,
    this.formatHint,
    this.package,
    this.file,
    this.videoQualityUrls,
    this.closedCaptionFile,
    this.videoPlayerOptions,
    this.httpHeaders = const {},
  });

  factory network(
    String dataSource, {
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    return PlayVideoFrom._(
      playerType: PodVideoPlayerType.network,
      dataSource: dataSource,
      formatHint: formatHint,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  }

  factory asset(
    String dataSource, {
    String? package,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
  }) {
    return PlayVideoFrom._(
      playerType: PodVideoPlayerType.asset,
      dataSource: dataSource,
      package: package,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
    );
  }

  ///File Doesnot support web apps
  ///[file] is `File` Datatype import it from `dart:io`
  factory file(
    File file, {
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
  }) {
    return PlayVideoFrom._(
      file: file,
      playerType: PodVideoPlayerType.file,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
    );
  }

  factory vimeo(
    String dataSource, {
    String? hash,
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    return PlayVideoFrom._(
      playerType: PodVideoPlayerType.vimeo,
      dataSource: dataSource,
      hash: hash,
      formatHint: formatHint,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  }

  factory vimeoPrivateVideos(
    String dataSource, {
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    return PlayVideoFrom._(
      playerType: PodVideoPlayerType.vimeoPrivateVideos,
      dataSource: dataSource,
      formatHint: formatHint,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  }
  factory youtube(
    String dataSource, {
    bool live = false,
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    return PlayVideoFrom._(
      live: live,
      playerType: PodVideoPlayerType.youtube,
      dataSource: dataSource,
      formatHint: formatHint,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  }
  factory networkQualityUrls({
    required List<VideoQalityUrls> videoUrls,
    VideoFormat? formatHint,
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const {},
  }) {
    return PlayVideoFrom._(
      playerType: PodVideoPlayerType.networkQualityUrls,
      videoQualityUrls: videoUrls,
      formatHint: formatHint,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  }
}
