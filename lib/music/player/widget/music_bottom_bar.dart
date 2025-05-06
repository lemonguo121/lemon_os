import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:lemon_tv/music/player/music_controller.dart';

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
  });
  final ThemeController themeController = Get.find();
  final MusicPlayerController playerController = Get.find();

  String _formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _playModeIconWidget(PlayMode mode) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 播放控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // 加这个也有帮助
            children: [
              // 收藏
              Obx(() {
                final isFav = playerController.isCurrentSongFavorite.value;
                return SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: 24,
                      color: isFav ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: () {
                      playerController.toggleFavorite();
                    },
                  ),
                );
              }),
              const SizedBox(width: 15),
              // 上一首
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.skip_previous, size: 28, color: Colors.white),
                  onPressed: onPrev,
                ),
              ),
              // 播放/暂停
              SizedBox(
                width: 64,
                height: 64,
                child: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 42,
                    color: Colors.white,
                  ),
                  onPressed: onPlayPause,
                ),
              ),
              // 下一首
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.skip_next, size: 28, color: Colors.white),
                  onPressed: onNext,
                ),
              ),
              const SizedBox(width: 20),
              // 菜单
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.menu, size: 24, color: Colors.white),
                  onPressed: showMenu,
                ),
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
                  activeColor: themeController.currentAppTheme.selectedTextColor,
                  inactiveColor: Colors.white24,
                  onChanged: onSeek,
                ),
              ),
              Text(
                _formatTime(total),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Obx((){
                return IconButton(
                  icon: _playModeIconWidget(playerController.playMode.value),
                  onPressed: playerController.togglePlayMode,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
