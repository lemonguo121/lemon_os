import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:lemon_tv/util/ThemeController.dart';

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
                      return Obx(() => ListTile(
                            visualDensity: VisualDensity(vertical: -2),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Icon(
                              Icons.music_note,
                              color: item.songBean.id ==
                                      controller.songBean.value.id
                                  ? themeController
                                      .currentAppTheme.selectedTextColor
                                  : Colors.black
                            ),
                            title: Text(
                              item.songBean.title,
                              style: TextStyle(
                                  color: item.songBean.id ==
                                          controller.songBean.value.id
                                      ? themeController
                                          .currentAppTheme.selectedTextColor
                                      : Colors.black,
                                  fontSize: 12),
                            ),
                            subtitle: item.songBean.artist != null
                                ? Text(
                                    item.songBean.artist!,
                                    style: TextStyle(
                                      color: item.songBean.id ==
                                              controller.songBean.value.id
                                          ? themeController
                                              .currentAppTheme.selectedTextColor
                                          : Colors.black,
                                      fontSize: 12, // 可选：调整字号
                                    ),
                                  )
                                : null,
                            onTap: () {
                              controller.playIndex.value = index;
                              controller.updataMedia(item);
                              var listName = MusicSPManage.getCurrentPlayType();
                              MusicSPManage.saveCurrentPlayIndex(listName,index);
                            },
                        trailing: GestureDetector(
                          child: Icon(Icons.close,color: Colors.red,),
                          onTap: (){
                            controller.removeSongInList(item);
                          },
                        ),
                          ));
                    },
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
