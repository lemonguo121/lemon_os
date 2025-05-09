import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import '../music_home/music_home_controller.dart';
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
  final MusicHomeController homeController = Get.find();
  final ScrollController scrollController = ScrollController();

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
        centerTitle: true,
      ),
      body: Obx(() {
        final list = controller.playList;
        var index = list.indexWhere((musicBean) =>
            musicBean.songBean.id == playerController.songBean.value.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            var itemHeight = 95.0.r; // 替换为你的实际高度
            scrollController.animateTo(
              index * itemHeight,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
            );
          }
        });
        if (list.isEmpty) {
          return Center(
            child: Text(
              '列表为空',
              style: TextStyle(
                color: themeController.currentAppTheme.selectedTextColor,
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildHotInfo(context),
            ),
            SizedBox(height: 28.h),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: list.length,
                controller: scrollController,
                itemBuilder: (context, index) {
                  return PlayListCell(
                    item: list[index],
                    index: index,
                    isBottomSheet: false,
                    isNeedDelete: true,
                    onDelete: deleteItem,
                    onClickItem: clickItem,
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  void deleteItem(MusicBean item) {
    controller.removeSongInList(item);
    if (controller.recordBean?.key == MusicSPManage.getCurrentPlayType().key) {
      playerController.removeSongInList(item);
    }
    homeController.recordList.refresh();
  }

  void clickItem() {}

  Widget _buildHotInfo(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = constraints.maxWidth * 0.25; // 25% 宽度作为图片尺寸

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: imageSize,
              height: imageSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: LoadingImage(
                  pic: CommonUtil.getCoverImg(controller.recordBean?.key ?? ""),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.recordBean?.name ?? "",
                    style: TextStyle(
                        fontSize: constraints.maxWidth * 0.05, // 5%宽度作为字体大小
                        fontWeight: FontWeight.bold,
                        color: themeController.currentAppTheme.normalTextColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '共 ${controller.playList.value.length} 首',
                    style: TextStyle(
                        fontSize: constraints.maxWidth * 0.03,
                        color:
                            themeController.currentAppTheme.selectedTextColor),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
