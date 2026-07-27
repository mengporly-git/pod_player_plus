part of 'package:pod_player_plus/src/pod_player.dart';

class FullScreenView extends StatefulWidget {
  final String tag;
  const FullScreenView({
    required this.tag,
    super.key,
  });

  @override
  State<FullScreenView> createState() => _FullScreenViewState();
}

class _FullScreenViewState extends State<FullScreenView>
    with TickerProviderStateMixin {
  late PodGetXVideoController _podCtr;
  @override
  void initState() {
    _podCtr = Get.find<PodGetXVideoController>(tag: widget.tag);
    _podCtr.fullScreenContext = context;
    _podCtr.keyboardFocusWeb?.removeListener(_podCtr.keyboardListener);

    super.initState();
  }

  @override
  void dispose() {
    _podCtr.keyboardFocusWeb?.requestFocus();
    _podCtr.keyboardFocusWeb?.addListener(_podCtr.keyboardListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadingWidget =
        _podCtr.onLoading?.call(context) ??
        const CircularProgressIndicator(
          backgroundColor: Colors.black87,
          color: Colors.white,
          strokeWidth: 2,
        );

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          unawaited(
            _podCtr.disableFullScreen(
              context,
              widget.tag,
              enablePop: false,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GetBuilder<PodGetXVideoController>(
          tag: widget.tag,
          builder: (podCtr) => Center(
            child: ColoredBox(
              color: Colors.black,
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Center(
                  child: podCtr.videoCtr == null
                      ? loadingWidget
                      : podCtr.videoCtr!.value.isInitialized
                      ? _PodCoreVideoPlayer(
                          tag: widget.tag,
                          videoPlayerCtr: podCtr.videoCtr!,
                          videoAspectRatio:
                              podCtr.videoCtr?.value.aspectRatio ?? 16 / 9,
                        )
                      : loadingWidget,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
