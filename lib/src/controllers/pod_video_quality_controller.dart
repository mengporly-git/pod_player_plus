part of 'pod_getx_video_controller.dart';

class _PodVideoQualityController extends _PodVideoController {
  ///
  int? vimeoPlayingVideoQuality;

  ///vimeo all quality urls
  List<VideoQalityUrls> vimeoOrVideoUrls = [];
  late String _videoQualityUrl;
  String? _audioQualityUrl;

  ///invokes callback from external controller
  VoidCallback? onVimeoVideoQualityChanged;

  ///*vimeo player configs
  ///
  ///get all  `quality urls`
  Future<void> getQualityUrlsFromVimeoId(
    String videoId, {
    String? hash,
  }) async {
    try {
      podVideoStateChanger(PodVideoState.loading);
      final vimeoVideoUrls = await VideoApis.getVimeoVideoQualityUrls(
        videoId,
        hash,
      );

      ///
      vimeoOrVideoUrls = vimeoVideoUrls ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> getQualityUrlsFromVimeoPrivateId(
    String videoId,
    Map<String, String> httpHeader,
  ) async {
    try {
      podVideoStateChanger(PodVideoState.loading);
      final vimeoVideoUrls = await VideoApis.getVimeoPrivateVideoQualityUrls(
        videoId,
        httpHeader,
      );

      ///
      vimeoOrVideoUrls = vimeoVideoUrls ?? [];
    } catch (e) {
      rethrow;
    }
  }

  void sortQualityVideoUrls(
    List<VideoQalityUrls>? urls,
  ) {
    final urls0 = urls;

    ///has issues with 240p
    urls0?.removeWhere((element) => element.quality == 240);

    ///has issues with 144p in web
    if (kIsWeb) {
      urls0?.removeWhere((element) => element.quality == 144);
    }

    ///sort
    urls0?.sort((a, b) => a.quality.compareTo(b.quality));

    ///
    vimeoOrVideoUrls = urls0 ?? [];
  }

  ///get vimeo quality `ex: 1080p` url
  VideoQalityUrls getQualityUrl(int quality) {
    return vimeoOrVideoUrls.firstWhere(
      (element) => element.quality == quality,
      orElse: () => vimeoOrVideoUrls.first,
    );
  }

  Future<String> getUrlFromVideoQualityUrls({
    required List<int> qualityList,
    required List<VideoQalityUrls> videoUrls,
  }) async {
    sortQualityVideoUrls(videoUrls);
    if (vimeoOrVideoUrls.isEmpty) {
      throw Exception('videoQuality cannot be empty');
    }

    final fallback = vimeoOrVideoUrls[0];
    VideoQalityUrls? urlWithQuality;
    for (final quality in qualityList) {
      urlWithQuality = vimeoOrVideoUrls.firstWhere(
        (url) => url.quality == quality,
        orElse: () => fallback,
      );

      if (urlWithQuality != fallback) {
        break;
      }
    }

    urlWithQuality ??= fallback;
    _videoQualityUrl = urlWithQuality.url;
    _audioQualityUrl = urlWithQuality.audioUrl;
    vimeoPlayingVideoQuality = urlWithQuality.quality;
    return _videoQualityUrl;
  }

  Future<List<VideoQalityUrls>> getVideoQualityUrlsFromYoutube(
    String youtubeIdOrUrl,
    bool live,
  ) async {
    return await VideoApis.getYoutubeVideoQualityUrls(youtubeIdOrUrl, live) ??
        [];
  }

  Future<void> changeVideoQuality(int? quality) async {
    if (vimeoOrVideoUrls.isEmpty) {
      throw Exception('videoQuality cannot be empty');
    }
    if (vimeoPlayingVideoQuality != quality) {
      final selectedQuality = vimeoOrVideoUrls.firstWhere(
        (element) => element.quality == quality,
      );
      _videoQualityUrl = selectedQuality.url;
      _audioQualityUrl = selectedQuality.audioUrl;
      podLog(_videoQualityUrl);
      vimeoPlayingVideoQuality = quality;

      final oldVideoController = _videoCtr;
      final oldAudioController = _audioCtr;
      final wasPlaying = oldVideoController?.value.isPlaying ?? isvideoPlaying;
      final oldVolume = isMute ? 0.0 : oldVideoController?.value.volume ?? 1.0;

      await _pausePlaybackControllers();
      podVideoStateChanger(PodVideoState.paused);
      podVideoStateChanger(PodVideoState.loading);
      playingVideoUrl = _videoQualityUrl;

      final newVideoController = VideoPlayerController.networkUrl(
        Uri.parse(_videoQualityUrl),
      );
      final newAudioController = _createAudioController(_audioQualityUrl);
      await Future.wait([
        newVideoController.initialize(),
        if (newAudioController != null) newAudioController.initialize(),
      ]);

      await Future.wait([
        newVideoController.setLooping(isLooping),
        newVideoController.setVolume(oldVolume),
        newVideoController.setPlaybackSpeed(_playbackSpeedValue),
        if (newAudioController != null) ...[
          newAudioController.setLooping(isLooping),
          newAudioController.setVolume(oldVolume),
          newAudioController.setPlaybackSpeed(_playbackSpeedValue),
        ],
      ]);

      oldVideoController?.removeListener(videoListener);
      _videoCtr = newVideoController..addListener(videoListener);
      _audioCtr = newAudioController;
      _videoDuration = _videoCtr?.value.duration ?? Duration.zero;
      await _seekPlaybackControllers(_videoPosition);

      await Future.wait([
        if (oldVideoController != null) oldVideoController.dispose(),
        if (oldAudioController != null) oldAudioController.dispose(),
      ]);

      if (wasPlaying) {
        podVideoStateChanger(PodVideoState.playing);
        await _playPlaybackControllers();
      } else {
        podVideoStateChanger(PodVideoState.paused);
      }
      onVimeoVideoQualityChanged?.call();
      update();
      update(['update-all']);
    }
  }
}
