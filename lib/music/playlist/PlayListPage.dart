import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lemon_tv/music/data/PlayRecordList.dart';
import 'package:lemon_tv/music/player/music_controller.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import '../../routes/routes.dart';
import '../../util/CommonUtil.dart';
import '../../util/widget/LoadingImage.dart';
import '../common/PlayListCell.dart';
import '../data/MusicBean.dart';
import '../data/SongBean.dart';
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
  PlayListController controller = Get.find();
  MusicPlayerController playerController = Get.find();

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
              Expanded(
                  child: Center(
                child: Text(
                  '列表为空',
                  style: TextStyle(
                      color: themeController.currentAppTheme.selectedTextColor),
                ),
              ))
            else
              Flexible(
                child: Obx(() {
                  final list = controller.playList;
                  print('list = ${list.length}');
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      return PlayListCell(
                        item: list[index],
                        index: index,
                        isBottomSheet: false,
                        onDelete: deleteItem,
                      );
                    },
                  );
                }),
              ),
          ],
        );
      }),
    );
  }
  void deleteItem(MusicBean item) {
    controller.removeSongInList(item);
    playerController.playList.refresh();
  }
}
