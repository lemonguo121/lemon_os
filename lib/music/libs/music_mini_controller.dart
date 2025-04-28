import 'dart:ui';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import 'music_controller.dart';

class MiniPlayerController extends GetxController {
  final MusicPlayerController musicController = Get.find<MusicPlayerController>();

  // 改为 Rx 类型
  RxBool isVisible = false.obs;
  RxString songName = "".obs;
  Rx<Duration> total = Duration.zero.obs;
  Rx<Duration> position = Duration.zero.obs;
  RxBool isPlaying = false.obs;

  VoidCallback? onPlayPause;
  VoidCallback? onNext;
  VoidCallback? onPrev;
  VoidCallback? onCloseCallback;

  void showMiniPlayer({
    required String name,
    required Duration totalDuration,
    required Duration current,
    required bool playing,
    VoidCallback? playPause,
    VoidCallback? prev,
    VoidCallback? next,
    VoidCallback? close,
  }) {
    // 使用 Rx 变量来更新值
    isVisible.value = true;
    songName.value = name;
    total.value = totalDuration;
    position.value = current;
    isPlaying.value = playing;
    onPlayPause = playPause;
    onNext = next;
    onPrev = prev;
    onCloseCallback = close;
  }

  void hideMiniPlayer() {
    isVisible.value = false;
  }

  void updateProgress(Duration pos, bool playing) {
    position.value = pos;
    isPlaying.value = playing;
  }

  Future<void> onPlayPauseAction() async {
    if (isPlaying.value) {
      await musicController.player.pause();
      isPlaying.value = false;
    } else {
      await musicController.player.play();
      isPlaying.value = true;
    }
  }
}