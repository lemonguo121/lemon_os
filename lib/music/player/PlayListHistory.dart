import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:lemon_tv/music/player/widget/music_play.dart';
import 'package:lemon_tv/music/player/widget/music_yinfu.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import '../data/MusicBean.dart';
import 'music_controller.dart';

class PlayListHistory extends StatefulWidget {
  const PlayListHistory({super.key});

  @override
  State<PlayListHistory> createState() => _PlayListHistoryState();
}

class _PlayListHistoryState extends State<PlayListHistory> {
  final MusicPlayerController controller = Get.find();
  final ThemeController themeController = Get.find();
  late  PlayMode _playMode = MusicSPManage.getCurrentPlayMode();
  final MusicPlayerController playerController = Get.find();
  Widget _playModeIconWidget() {
    switch (_playMode) {
      case PlayMode.single:
        return Image.asset('assets/music/repeat.png', width: 20, height: 20,color: themeController.currentAppTheme.selectedTextColor);
      case PlayMode.loop:
      default:
      return Image.asset('assets/music/loop.png', width: 20, height: 20,color: themeController.currentAppTheme.selectedTextColor);
    }
  }
  @override
  Widget build(BuildContext context) {
    print('******* playListHistory = ${controller.playList.length}');
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 500,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Obx(() {
          final list = controller.playList;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部标题 + 播放模式按钮
              SizedBox(
                height: 40,
                child: Stack(
                  children: [
                    const Center(
                      child: Text(
                        '播放列表',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,color:Colors.black),
                      ),
                    ),
                    Positioned(
                      right: -5,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: _playModeIconWidget(), // 你已有的方法，返回一个Icon组件
                        onPressed: () {
                          setState(() {
                            _playMode = _playMode == PlayMode.loop ? PlayMode.single : PlayMode.loop;
                          });
                          playerController.player.setLoopMode(
                            _playMode == PlayMode.loop ? LoopMode.all : LoopMode.one,
                          );
                          print('当前播放器的模式。。。。。${playerController.player.loopMode}');

                          MusicSPManage.saveCurrentPlayMode(_playMode);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (controller.playList.isEmpty)
                const Text('列表为空')
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.playList.length,
                    itemBuilder: (context, index) {
                      final item = controller.playList[index];
                      return Obx(() => playListCell(item, index));
                    },
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget playListCell(MusicBean item, int index) {
    final bool isPlaying = item.songBean.id == controller.songBean.value.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8), // 每个 cell 上下间距
      child: InkWell(
        onTap: () {
          controller.playIndex.value = index;
          controller.updataMedia(item);
          var listName = MusicSPManage.getCurrentPlayType();
          MusicSPManage.saveCurrentPlayIndex(listName, index);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: isPlaying
                  ? AudioBarsAnimated(
                barWidth: 2,
                barHeight: 10,
                color: Colors.redAccent,
              )
                  : const SizedBox(),
            ),
            // const SizedBox(width: 8),
            ClipOval(
              child: Image.asset(
                'assets/music/record.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.songBean.title,
                    style: TextStyle(
                      color: isPlaying
                          ? themeController.currentAppTheme.selectedTextColor
                          : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.songBean.artist != null)
                    Text(
                      item.songBean.artist!,
                      style: TextStyle(
                        color: isPlaying
                            ? themeController.currentAppTheme.selectedTextColor
                            : Colors.grey,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                controller.removeSongInList(item);
              },
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.close, color: Colors.red, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
