import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lemon_tv/util/CommonUtil.dart';
import 'package:lemon_tv/util/widget/LoadingImage.dart';
import 'package:marquee/marquee.dart';

import '../../../util/ThemeController.dart';
import '../../music_utils/MusicSPManage.dart';
import '../PlayListHistory.dart';
import '../music_controller.dart';

class MiniMusicPlayerBar extends StatefulWidget {
  const MiniMusicPlayerBar({super.key});

  @override
  State<MiniMusicPlayerBar> createState() => _MiniMusicPlayerBarState();
}

class _MiniMusicPlayerBarState extends State<MiniMusicPlayerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  final MusicPlayerController playerController =
      Get.find<MusicPlayerController>();
  final ThemeController themeController = Get.find();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    print("音乐名字:${playerController.songBean.value.title}");
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    playerController.player.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: () {
            if (Get.currentRoute != '/musicPlayer') {
              Get.toNamed('/musicPlayer'); // 跳到完整播放器页
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Obx(() {
              // 仅当依赖的 Rx 变量发生变化时更新以下部分
              return Row(
                children: [
                  // 唱片封面
                  CircleAvatar(
                    radius: 22,
                    child: ClipOval(
                      child: LoadingImage(
                        pic: playerController.getCover(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 歌曲信息
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 20,
                          child: Marquee(
                            text: "正在播放：${playerController.getTitle()}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            scrollAxis: Axis.horizontal,
                            blankSpace: 60.0,
                            velocity: 30.0,
                            pauseAfterRound: Duration.zero,
                            startPadding: 0.0,
                            accelerationDuration: Duration.zero,
                            accelerationCurve: Curves.linear,
                            decelerationDuration: Duration.zero,
                            decelerationCurve: Curves.easeOut,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_formatDuration(playerController.currentPosition.value)} / ${_formatDuration(playerController.totalDuration.value)}",
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 播放控制按钮
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous,
                            color: Colors.white),
                        onPressed: playerController.onPrev,
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      Obx(() {
                        return IconButton(
                          icon: Icon(
                            playerController.isPlaying.value
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: goPlay,
                          iconSize: 28,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        );
                      }),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: playerController.onNext,
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  // 关闭按钮
                  IconButton(
                    icon: Icon(Icons.menu, color: Colors.white, size: 24),
                    onPressed: showBottomMenu,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Obx((){
                    return IconButton(
                      icon: _playModeIconWidget(playerController.playMode.value), // 你已有的方法，返回一个Icon组件
                      onPressed: () {
                        playerController.togglePlayMode();
                      },
                    );
                  })
                ],
              );
            }),
          ),
        ));
  }
  Widget _playModeIconWidget(PlayMode mode) {
    switch (mode) {
      case PlayMode.single:
        return Image.asset('assets/music/repeat.png',
            width: 20,
            height: 20,
            color: themeController.currentAppTheme.selectedTextColor);
      case PlayMode.loop:
      default:
        return Image.asset('assets/music/loop.png',
            width: 20,
            height: 20,
            color: themeController.currentAppTheme.selectedTextColor);
    }
  }
  void showBottomMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Wrap(
        children: const [
          PlayListHistory(),
        ],
      ),
    );
  }

  /// 格式化时间显示 MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  goPlay() {
    if (playerController.player.playerState.processingState==ProcessingState.ready) {
      playerController.playPause();
    } else {
      playerController.upDataSong(playerController.songBean.value);
    }
  }
}
