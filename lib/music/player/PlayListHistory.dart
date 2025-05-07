import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/data/MusicBean.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:lemon_tv/music/playlist/PlayListController.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import '../common/PlayListCell.dart';
import 'music_controller.dart';

class PlayListHistory extends StatefulWidget {
  const PlayListHistory({super.key});

  @override
  State<PlayListHistory> createState() => _PlayListHistoryState();
}

class _PlayListHistoryState extends State<PlayListHistory> {
  final MusicPlayerController controller = Get.find();
  final PlayListController playListController = Get.find();
  final ThemeController themeController = Get.find();

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

  @override
  void initState() {
    super.initState();
    playListController.recordBean = MusicSPManage.getCurrentPlayType();
  }

  @override
  Widget build(BuildContext context) {
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
                child: Row(
                  children: [
                    SizedBox(
                      width: 24.w,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            getPlayListName(),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          SizedBox(
                            width: 12.w,
                          ),
                          Text(
                            '(共${list.length}首)',
                            style: TextStyle(fontSize: 12, color: Colors.black),
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                          _playModeIconWidget(controller.playMode.value),
                      // 你已有的方法，返回一个Icon组件
                      onPressed: () {
                        controller.togglePlayMode();
                      },
                    ),
                    SizedBox(width: 24.w)
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (controller.playList.isEmpty)
                Expanded(
                    child: Center(
                  child: Text(
                    '列表为空',
                    style: TextStyle(
                        color:
                            themeController.currentAppTheme.selectedTextColor),
                  ),
                ))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.playList.length,
                    itemBuilder: (context, index) {
                      final item = controller.playList[index];
                      return PlayListCell(
                          item: item, index: index, isBottomSheet: true,isNeedDelete:true,onDelete: deleteItem,onClickItem: clickItem,);
                    },
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  String getPlayListName() {
    var playRecord = MusicSPManage.getCurrentPlayType();
    return playRecord.name;
  }

  void deleteItem(MusicBean item) {
    controller.removeSongInList(item);
    playListController.playList.refresh();
  }

  void clickItem() {
  }
}
