import 'package:flutter/material.dart';

class MiniPlayerController extends ChangeNotifier {
  bool isVisible = false;
  String songName = "";
  Duration total = Duration.zero;
  Duration position = Duration.zero;
  bool isPlaying = false;

  VoidCallback? onPlayPause;
  VoidCallback? onNext;
  VoidCallback? onPrev;
  VoidCallback? onClose;

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
    isVisible = true;
    songName = name;
    total = totalDuration;
    position = current;
    isPlaying = playing;
    onPlayPause = playPause;
    onNext = next;
    onPrev = prev;
    onClose = close;
    notifyListeners();
  }

  void hideMiniPlayer() {
    isVisible = false;
    notifyListeners();
  }

  void updateProgress(Duration pos, bool playing) {
    position = pos;
    isPlaying = playing;
    notifyListeners();
  }
}
