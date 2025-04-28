import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'music_mini_controller.dart';

class MiniMusicPlayerBar extends StatefulWidget {
  final MiniPlayerController controller;

  const MiniMusicPlayerBar({super.key, required this.controller});

  @override
  State<MiniMusicPlayerBar> createState() => _MiniMusicPlayerBarState();
}

class _MiniMusicPlayerBarState extends State<MiniMusicPlayerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  final MiniPlayerController miniController = Get.find<MiniPlayerController>();

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
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    miniController.musicController.player.stop();
    super.dispose();
  }

  void _closePlayer() async {
    await _controller.reverse();
    await miniController.musicController.player.stop();
    miniController.hideMiniPlayer();
    miniController.onClose?.call(); // 加个问号保险，防止 onClose == null
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: (){
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
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/music/record.png'),
                  radius: 22,
                ),
                const SizedBox(width: 12),
                // 歌曲信息
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "正在播放：${miniController.songName}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_formatDuration(miniController.position.value)} / ${_formatDuration(miniController.total.value)}",
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
                      icon: const Icon(Icons.skip_previous, color: Colors.white),
                      onPressed: miniController.onPrev,
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    Obx((){
                      return IconButton(
                        icon: Icon(
                          miniController.isPlaying.value ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: miniController.onPlayPauseAction,
                        iconSize: 28,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    }),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      onPressed: miniController.onNext,
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                // 关闭按钮
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: _closePlayer,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            );
          }),
        ),
      )
    );
  }

  /// 格式化时间显示 MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}