import 'package:flutter/material.dart';
import 'package:pod_player_plus/pod_player_plus.dart';

class PlayVideoFromYoutube extends StatefulWidget {
  const PlayVideoFromYoutube({super.key});

  @override
  State<PlayVideoFromYoutube> createState() => _PlayVideoFromVimeoIdState();
}

class _PlayVideoFromVimeoIdState extends State<PlayVideoFromYoutube> {
  late final PodPlayerController controller;
  final videoTextFieldCtr = TextEditingController();

  @override
  void initState() {
    controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.youtube('https://www.youtube.com/watch?v=0jSgcE-sxeo'),
      podPlayerConfig: const PodPlayerConfig(
        videoQualityPriority: [1080, 720, 360],
        autoPlay: false,
      ),
    )..initialise();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Youtube player')),
      body: SafeArea(
        child: Center(
          child: ListView(
            shrinkWrap: true,
            children: [
              PodVideoPlayer(controller: controller),
              const SizedBox(height: 40),
              _loadVideoFromUrl(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadVideoFromUrl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        spacing: 8,
        children: [
          TextField(
            controller: videoTextFieldCtr,
            decoration: const InputDecoration(
              labelText: 'Enter youtube url/id',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintText: 'https://www.youtube.com/watch?v=0jSgcE-sxeo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(width: 10),
          FocusScope(
            canRequestFocus: false,
            child: ElevatedButton(
              onPressed: () async {
                if (videoTextFieldCtr.text.isEmpty) {
                  snackBar('Please enter the url');
                  return;
                }
                try {
                  snackBar('Loading....');
                  FocusScope.of(context).unfocus();
                  await controller.changeVideo(
                    playVideoFrom: PlayVideoFrom.youtube(
                      videoTextFieldCtr.text,
                    ),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                } catch (e) {
                  snackBar('Unable to load,\n $e');
                }
              },
              child: const Text('Load Video'),
            ),
          ),
        ],
      ),
    );
  }

  void snackBar(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
