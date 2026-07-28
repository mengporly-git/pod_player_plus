part of 'pod_getx_video_controller.dart';

class _PodVideoController extends _PodUiController {
  Timer? showOverlayTimer;
  Timer? showOverlayTimer1;

  bool isOverlayVisible = true;
  bool isLooping = false;
  bool isFullScreen = false;
  bool isvideoPlaying = false;

  List<String> videoPlaybackSpeeds = [
    '0.25x',
    '0.5x',
    '0.75x',
    '1x',
    '1.25x',
    '1.5x',
    '1.75x',
    '2x',
  ];

  ///

  ///*seek video
  /// Seek video to a duration.
  Future<void> seekTo(Duration moment) async {
    final wasPlaying = _videoCtr?.value.isPlaying ?? false;
    await _pausePlaybackControllers();
    await _seekPlaybackControllers(moment);
    if (wasPlaying) {
      await _playPlaybackControllers();
    }
  }

  /// Seek video forward by the duration.
  Future<void> seekForward(Duration videoSeekDuration) async {
    await seekTo(_videoCtr!.value.position + videoSeekDuration);
  }

  /// Seek video backward by the duration.
  Future<void> seekBackward(Duration videoSeekDuration) async {
    await seekTo(_videoCtr!.value.position - videoSeekDuration);
  }

  ///mute
  /// Toggle mute.
  Future<void> toggleMute() async {
    isMute = !isMute;
    if (isMute) {
      await mute();
    } else {
      await unMute();
    }
  }

  Future<void> mute() async {
    await setVolume(0);
    update(['volume']);
    update(['update-all']);
  }

  Future<void> unMute() async {
    await setVolume(1);
    update(['volume']);
    update(['update-all']);
  }

  // Set volume between 0.0 - 1.0,
  /// 0.0 is mute and 1.0 max volume.
  Future<void> setVolume(
    double volume,
  ) async {
    await Future.wait([
      if (_videoCtr != null) _videoCtr!.setVolume(volume),
      if (_audioCtr != null) _audioCtr!.setVolume(volume),
    ]);
    if (volume <= 0) {
      isMute = true;
    } else {
      isMute = false;
    }
    update(['volume']);
    update(['update-all']);
  }

  ///*controll play pause
  Future<void> playVideo(bool val) async {
    isvideoPlaying = val;
    if (isvideoPlaying) {
      isShowOverlay(true);
      await _playPlaybackControllers();
      isShowOverlay(false, delay: const Duration(seconds: 1));
    } else {
      isShowOverlay(true);
      await _pausePlaybackControllers();
    }
  }

  ///toogle play pause
  void togglePlayPauseVideo() {
    isvideoPlaying = !isvideoPlaying;
    podVideoStateChanger(
      isvideoPlaying ? PodVideoState.playing : PodVideoState.paused,
    );
  }

  ///toogle video player controls
  void isShowOverlay(bool val, {Duration? delay}) {
    showOverlayTimer1?.cancel();
    showOverlayTimer1 = Timer(delay ?? Duration.zero, () {
      if (isOverlayVisible != val) {
        isOverlayVisible = val;
        update(['overlay']);
        update(['update-all']);
      }
    });
  }

  ///overlay above video contrller
  void toggleVideoOverlay() {
    if (!isOverlayVisible) {
      isOverlayVisible = true;
      update(['overlay']);
      update(['update-all']);
      return;
    }
    if (isOverlayVisible) {
      isOverlayVisible = false;
      update(['overlay']);
      update(['update-all']);
      showOverlayTimer?.cancel();
      showOverlayTimer = Timer(const Duration(seconds: 3), () {
        if (isOverlayVisible) {
          isOverlayVisible = false;
          update(['overlay']);
          update(['update-all']);
        }
      });
    }
  }

  Future<void> setVideoPlayBack(String speed) async {
    _currentPaybackSpeed = speed;
    await Future.wait([
      if (_videoCtr != null) _videoCtr!.setPlaybackSpeed(_playbackSpeedValue),
      if (_audioCtr != null) _audioCtr!.setPlaybackSpeed(_playbackSpeedValue),
    ]);
  }

  double get _playbackSpeedValue => _currentPaybackSpeed == 'Normal'
      ? 1
      : double.parse(_currentPaybackSpeed.split('x').first);

  Future<void> setLooping(bool isLooped) async {
    isLooping = isLooped;
    await Future.wait([
      if (_videoCtr != null) _videoCtr!.setLooping(isLooping),
      if (_audioCtr != null) _audioCtr!.setLooping(isLooping),
    ]);
  }

  Future<void> toggleLooping() async {
    isLooping = !isLooping;
    await Future.wait([
      if (_videoCtr != null) _videoCtr!.setLooping(isLooping),
      if (_audioCtr != null) _audioCtr!.setLooping(isLooping),
    ]);
    update();
    update(['update-all']);
  }

  VideoPlayerController? _createAudioController(String? audioUrl) {
    if (audioUrl == null) return null;
    return VideoPlayerController.networkUrl(
      Uri.parse(audioUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
  }

  Future<void> _playPlaybackControllers() async {
    final videoController = _videoCtr;
    if (videoController == null) return;

    final audioController = _audioCtr;
    if (audioController != null) {
      final drift =
          audioController.value.position - videoController.value.position;
      if (drift.abs() > const Duration(milliseconds: 250)) {
        await audioController.seekTo(videoController.value.position);
      }
    }

    await videoController.play();
    if (audioController != null) {
      await audioController.play();
      _startAudioSynchronization();
    }
  }

  Future<void> _pausePlaybackControllers() async {
    _stopAudioSynchronization();
    await Future.wait([
      if (_audioCtr != null) _audioCtr!.pause(),
      if (_videoCtr != null) _videoCtr!.pause(),
    ]);
  }

  Future<void> _seekPlaybackControllers(Duration position) async {
    final videoController = _videoCtr;
    if (videoController == null) return;

    await videoController.seekTo(position);
    final actualPosition = videoController.value.position;
    if (_audioCtr != null) {
      await _audioCtr!.seekTo(actualPosition);
    }
  }

  void _startAudioSynchronization() {
    _audioSyncTimer?.cancel();
    _audioSyncTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => unawaited(_synchronizeAudio()),
    );
  }

  void _stopAudioSynchronization() {
    _audioSyncTimer?.cancel();
    _audioSyncTimer = null;
  }

  Future<void> _synchronizeAudio() async {
    if (_isSynchronizingAudio) return;

    final videoController = _videoCtr;
    final audioController = _audioCtr;
    if (videoController == null ||
        audioController == null ||
        !videoController.value.isInitialized ||
        !audioController.value.isInitialized) {
      return;
    }

    _isSynchronizingAudio = true;
    try {
      if (!videoController.value.isPlaying) {
        if (audioController.value.isPlaying) {
          await audioController.pause();
        }
        return;
      }

      if (videoController.value.isBuffering) {
        if (audioController.value.isPlaying) {
          await audioController.pause();
        }
        return;
      }

      final drift =
          audioController.value.position - videoController.value.position;
      if (drift.abs() > const Duration(milliseconds: 400)) {
        await audioController.seekTo(videoController.value.position);
      }
      if (!audioController.value.isPlaying &&
          !audioController.value.isBuffering) {
        await audioController.play();
      }
    } finally {
      _isSynchronizingAudio = false;
    }
  }

  Future<void> disposePlaybackControllers() async {
    _stopAudioSynchronization();
    final videoController = _videoCtr;
    final audioController = _audioCtr;
    videoController?.removeListener(videoListener);
    _videoCtr = null;
    _audioCtr = null;
    await Future.wait([
      if (videoController != null) videoController.dispose(),
      if (audioController != null) audioController.dispose(),
    ]);
  }

  Future<void> enableFullScreen(String tag) async {
    podLog('-full-screen-enable-entred');
    if (!isFullScreen) {
      if (onToggleFullScreen != null) {
        await onToggleFullScreen!(true);
      } else {
        await Future.wait([
          SystemChrome.setPreferredOrientations(
            [
              if (!kIsWeb) DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
          ),
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
        ]);
      }

      _enableFullScreenView(tag);
      isFullScreen = true;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        update(['full-screen']);
        update(['update-all']);
      });
    }
  }

  Future<void> disableFullScreen(
    BuildContext context,
    String tag, {
    bool enablePop = true,
  }) async {
    podLog('-full-screen-disable-entred');
    if (isFullScreen) {
      if (onToggleFullScreen != null) {
        await onToggleFullScreen!(false);
      } else {
        await Future.wait([
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]),
          if (!(defaultTargetPlatform == TargetPlatform.iOS)) ...[
            SystemChrome.setPreferredOrientations(DeviceOrientation.values),
            SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: SystemUiOverlay.values,
            ),
          ],
        ]);
      }

      if (enablePop) _exitFullScreenView(context, tag);
      isFullScreen = false;
      update(['full-screen']);
      update(['update-all']);
    }
  }

  void _exitFullScreenView(BuildContext context, String tag) {
    podLog('popped-full-screen');
    Navigator.of(fullScreenContext).pop();
  }

  void _enableFullScreenView(String tag) {
    if (!isFullScreen) {
      podLog('full-screen-enabled');

      unawaited(
        Navigator.push(
          mainContext,
          PageRouteBuilder<dynamic>(
            fullscreenDialog: true,
            pageBuilder: (context, _, _) => FullScreenView(
              tag: tag,
            ),
            reverseTransitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
          ),
        ),
      );
    }
  }

  /// Calculates video `position` or `duration`
  String calculateVideoDuration(Duration duration) {
    final totalHour = duration.inHours == 0 ? '' : '${duration.inHours}:';
    final totalMinute = duration.toString().split(':')[1];
    final totalSeconds = (duration - Duration(minutes: duration.inMinutes))
        .inSeconds
        .toString()
        .padLeft(2, '0');
    final String videoLength = '$totalHour$totalMinute:$totalSeconds';
    return videoLength;
  }
}
