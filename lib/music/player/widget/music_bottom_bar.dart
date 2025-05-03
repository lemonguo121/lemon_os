import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';

import '../../../util/ThemeController.dart';

class MusicBottomBar extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration total;
  final VoidCallback onPlayPause;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback showMenu;
  final Function(double) onSeek;
  final VoidCallback onModeTap;
  MusicBottomBar({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.total,
    required this.onPlayPause,
    required this.onPrev,
    required this.onNext,
    required this.showMenu,
    required this.onSeek,
    required this.onModeTap,
  });
  final ThemeController themeController = Get.find();

  String _formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _playModeIconWidget() {
    print('当前播放模式为****${MusicSPManage.getCurrentPlayMode()}');
    switch (MusicSPManage.getCurrentPlayMode()) {
      case PlayMode.single:
        return Image.asset('assets/music/repeat.png', width: 20, height: 20,color: themeController.currentAppTheme.selectedTextColor,);
      case PlayMode.loop:
      default:
        return Image.asset('assets/music/loop.png', width: 20, height: 20,color: themeController.currentAppTheme.selectedTextColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 8),
      color: Colors.black.withOpacity(0.6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 播放控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous,
                    color: Colors.white, size: 28),
                onPressed: onPrev,
              ),
              IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 42,
                ),
                onPressed: onPlayPause,
              ),
              IconButton(
                icon:
                    const Icon(Icons.skip_next, color: Colors.white, size: 28),
                onPressed: onNext,
              ),
              SizedBox(
                width: 10,
              ),
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                onPressed: showMenu,
              ),
            ],
          ),

          const SizedBox(height: 0),

          // 时间 + 播放模式 + 进度条
          Row(
            children: [
              Text(
                _formatTime(position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value:
                      position.inSeconds.clamp(0, total.inSeconds).toDouble(),
                  min: 0,
                  max: total.inSeconds.toDouble(),
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white24,
                  onChanged: onSeek,
                ),
              ),
              Text(
                _formatTime(total),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              IconButton(
                icon: _playModeIconWidget(),
                onPressed: onModeTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
