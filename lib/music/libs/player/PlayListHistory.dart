import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/libs/player/music_controller.dart';
import 'package:lemon_tv/util/ThemeController.dart';

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
                '历史播放记录',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const Text('暂无播放记录')
              else
                Obx(() => Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return ListTile(
                            leading: Icon(Icons.music_note,
                                color: index == controller.playIndex.value
                                    ? themeController
                                        .currentAppTheme.selectedTextColor
                                    : themeController
                                        .currentAppTheme.normalTextColor),
                            title: Text(
                              item.songBean.title,
                              style: TextStyle(
                                  color: index == controller.playIndex.value
                                      ? themeController
                                          .currentAppTheme.selectedTextColor
                                      : themeController
                                          .currentAppTheme.normalTextColor),
                            ),
                            subtitle: item.songBean.artist != null
                                ? Text(item.songBean.artist!)
                                : null,
                            onTap: () {
                              controller.playIndex.value = index;
                              controller.updataMedia(item);
                            },
                          );
                        },
                      ),
                    )),
            ],
          );
        }),
      ),
    );
  }
}
