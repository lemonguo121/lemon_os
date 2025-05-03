import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lemon_tv/music/data/PlayRecordList.dart';
import 'package:lemon_tv/music/player/music_controller.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import '../data/MusicBean.dart';
import '../music_utils/MusicSPManage.dart';
import '../player/widget/music_yinfu.dart';
import 'PlayListController.dart';

class PlayListPage extends StatefulWidget {
  const PlayListPage({super.key});

  @override
  State<PlayListPage> createState() => _PlayListPageState();
}

class _PlayListPageState extends State<PlayListPage> {
  ThemeController themeController = Get.find();
  PlayListController controller = Get.put(PlayListController());
  PlayMode _playMode = MusicSPManage.getCurrentPlayMode();
  MusicPlayerController playerController = Get.find();

  Widget _playModeIconWidget() {
    switch (_playMode) {
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

  @override
  void initState() {
    super.initState();
    var arguments = Get.arguments;
    controller.recordBean = arguments['record'];
    controller.getPlayList();
  }

  @override
  void dispose() {
    super.dispose();
    Get.delete<PlayListController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: themeController.currentAppTheme.normalTextColor),
        title: Text(' ${controller.recordBean?.name}',
            style: TextStyle(
                color: themeController.currentAppTheme.normalTextColor)),
        centerTitle: true,
      ),
      body: Obx(() {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部标题 + 播放模式按钮
            if (controller.playList.isEmpty)
              const Expanded(
                  child: Center(
                child: Text('列表为空'),
              ))
            else
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
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
    );
  }

  Widget playListCell(MusicBean item, int index) {
    final bool isPlaying =
        item.songBean.id == playerController.songBean.value.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8), // 每个 cell 上下间距
      child: InkWell(
        onTap: () {
          playerController.playIndex.value = index;
          playerController.updataMedia(item);
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
                playerController.removeSongInList(item);
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
