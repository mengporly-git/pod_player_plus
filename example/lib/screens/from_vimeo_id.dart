import 'dart:async';

import 'package:pod_player_plus/pod_player_plus.dart';
import 'package:flutter/material.dart';

class PlayVideoFromVimeoId extends StatefulWidget {
  const PlayVideoFromVimeoId({super.key});

  @override
  State<PlayVideoFromVimeoId> createState() => _PlayVideoFromVimeoIdState();
}

class _PlayVideoFromVimeoIdState extends State<PlayVideoFromVimeoId> {
  late final PodPlayerController controller;
  final videoTextFieldCtr = TextEditingController();
  final hashTextFieldCtr = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.vimeo('1179947837'),
    );
    unawaited(_initialiseController());
  }

  Future<void> _initialiseController() async {
    try {
      await controller.initialise();
    } on Object catch (error) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) snackBar('Unable to load Vimeo video:\n$error');
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vimeo Player')),
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
    return Column(
      spacing: 8,
      children: [
        TextField(
          controller: videoTextFieldCtr,
          decoration: const InputDecoration(
            labelText: 'Enter vimeo id',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: 'ex: 1179947837',
            border: OutlineInputBorder(),
          ),
        ),
        TextField(
          controller: hashTextFieldCtr,
          decoration: const InputDecoration(
            labelText: 'Enter vimeo hash',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: 'ex: ddefbc',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(width: 10),
        FocusScope(
          canRequestFocus: false,
          child: ElevatedButton(
            onPressed: () async {
              if (videoTextFieldCtr.text.isEmpty) {
                snackBar('Please enter the id');
                return;
              }
              try {
                snackBar('Loading....');
                FocusScope.of(context).unfocus();
                final vimeoHash = hashTextFieldCtr.text;
                await controller.changeVideo(
                  playVideoFrom: PlayVideoFrom.vimeo(
                    videoTextFieldCtr.text,
                    hash: vimeoHash.isNotEmpty ? vimeoHash : null,
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
    );
  }

  void snackBar(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
