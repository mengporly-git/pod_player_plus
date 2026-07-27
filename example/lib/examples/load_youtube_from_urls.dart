import 'package:flutter/material.dart';
import 'package:pod_player_plus/pod_player_plus.dart';

void main(List<String> args) {
  runApp(const YoutubeApp());
}

class YoutubeApp extends StatelessWidget {
  const YoutubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Load youtube video from quality urls'),
        ),
        body: const YoutubeVideoViewer(),
      ),
    );
  }
}

class YoutubeVideoViewer extends StatefulWidget {
  const YoutubeVideoViewer({super.key});

  @override
  State<YoutubeVideoViewer> createState() => _YoutubeVideoViewerState();
}

class _YoutubeVideoViewerState extends State<YoutubeVideoViewer> {
  late final PodPlayerController controller;
  bool isLoading = true;
  @override
  void initState() {
    loadVideo();
    super.initState();
  }

  void loadVideo() async {
    final urls = await PodPlayerController.getYoutubeUrls(
      'https://youtu.be/A3ltMaM6noM',
    );
    setState(() => isLoading = false);
    controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.networkQualityUrls(videoUrls: urls!),
      podPlayerConfig: const PodPlayerConfig(
        videoQualityPriority: [1080, 720, 360],
      ),
    )..initialise();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Center(child: PodVideoPlayer(controller: controller));
  }
}
