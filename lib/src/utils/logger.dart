import 'dart:developer';

import '../../pod_player_plus.dart';

void podLog(String message) =>
    PodVideoPlayer.enableLogs ? log(message, name: 'POD') : null;
