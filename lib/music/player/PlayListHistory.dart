import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
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
              const Text(
                '播放列表',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const Text('列表为空')
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return Obx(() => playListCell(item,index));
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

    return InkWell(
      onTap: () {
        controller.playIndex.value = index;
        controller.updataMedia(item);
        var listName = MusicSPManage.getCurrentPlayType();
        MusicSPManage.saveCurrentPlayIndex(listName, index);
      },
      child: SizedBox(
        height: 66.h,
        child: Row(
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
                  : null,
            ),
            const SizedBox(width: 8),
            ClipOval(
              child: Image.asset(
                'assets/music/record.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
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
                      fontSize: 12,
                    ),
                  ),
                  if (item.songBean.artist != null)
                    Text(
                      item.songBean.artist!,
                      style: TextStyle(
                        color: isPlaying
                            ? themeController.currentAppTheme.selectedTextColor
                            : Colors.black,
                        fontSize: 12,
                      ),
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
                child: Icon(Icons.close, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
