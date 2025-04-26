import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'music_mini_controller.dart';

class MiniMusicPlayerBar extends StatefulWidget {
  const MiniMusicPlayerBar({super.key});

  @override
  State<MiniMusicPlayerBar> createState() => _MiniMusicPlayerBarState();
}

class _MiniMusicPlayerBarState extends State<MiniMusicPlayerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

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

    _controller.forward(); // 播放出现动画
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closePlayer() {
    _controller.reverse().then((_) {
      // 调用控制器隐藏（比如 GetX）
      Get.find<MiniPlayerController>().hideMiniPlayer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 唱片头像
            CircleAvatar(
              backgroundImage: AssetImage('assets/music/record.png'),
              radius: 22,
            ),
            const SizedBox(width: 10),
            // 歌名 + 歌手
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("正在播放：某首歌", style: TextStyle(color: Colors.white)),
                  SizedBox(height: 2),
                  Text("歌手名", style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            // 播放控制
            IconButton(
              icon: Icon(Icons.skip_previous, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.pause, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.skip_next, color: Colors.white),
              onPressed: () {},
            ),
            // 关闭按钮
            IconButton(
              icon: Icon(Icons.close, color: Colors.redAccent, size: 20),
              onPressed: _closePlayer,
            ),
          ],
        ),
      ),
    );
  }
}
