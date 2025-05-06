import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/routes.dart';
import '../../util/CommonUtil.dart';
import '../../util/ThemeController.dart';
import '../../util/widget/LoadingImage.dart';
import '../data/MusicBean.dart';
import '../data/SongBean.dart';
import '../music_utils/MusicSPManage.dart';
import '../player/music_controller.dart';
import '../player/widget/music_yinfu.dart';
import '../playlist/PlayListController.dart';

class PlayListCell extends StatelessWidget {
  final MusicBean item;
  final int index;
  final bool isBottomSheet; //用来区分是底部弹起列表还是普通列表,底部弹窗背景一直是白色，所以要单独处理眼
  final bool isNeedDelete; //用来区分是榜单详情，不需要删除按钮
  final ValueChanged<MusicBean> onDelete;
  final VoidCallback onClickItem;

  PlayListCell(
      {super.key,
      required this.item,
      required this.index,
      required this.isBottomSheet,
      required this.isNeedDelete,
      required this.onDelete,
      required this.onClickItem});

  final ThemeController themeController = Get.find();
  final PlayListController controller = Get.find();
  final MusicPlayerController playerController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isPlaying =
          item.songBean.id == playerController.songBean.value.id;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: () => playIndex(index, item),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              isPlaying
                  ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: AudioBarsAnimated(
                        barWidth: 2,
                        barHeight: 10,
                        color: Colors.redAccent,
                      ),
                    )
                  : const SizedBox.shrink(), // 保持结构对齐
              const SizedBox(width: 6),
              SizedBox(
                width: 36,
                height: 36,
                child: ClipOval(
                  child: LoadingImage(pic: getCover(item.songBean)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.songBean.title.isEmpty
                          ? item.songBean.artist
                          : item.songBean.title,
                      style: TextStyle(
                        color: isPlaying
                            ? themeController.currentAppTheme.selectedTextColor
                            : isBottomSheet
                                ? Colors.black
                                : themeController
                                    .currentAppTheme.normalTextColor,
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
                              ? themeController
                                  .currentAppTheme.selectedTextColor
                              : Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    item.songBean.platform,
                    style: TextStyle(
                      fontSize: 12,
                      color: isPlaying
                          ? themeController.currentAppTheme.selectedTextColor
                          : Colors.grey,
                    ),
                  ),
                  isNeedDelete?
                  InkWell(
                    onTap: () {
                      if (isPlaying &&
                          controller.recordBean?.key ==
                              MusicSPManage.getCurrentPlayType().key) {
                        playerController.onNext();
                      }
                      onDelete(item);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.close, color: Colors.red, size: 18),
                    ),
                  ):SizedBox.shrink(),
                ],
              )
            ],
          ),
        ),
      );
    });
  }

  String getCover(SongBean songBean) {
    var artwork = songBean.artwork;
    if (artwork.isEmpty || !artwork.startsWith('http')) {
      return CommonUtil.getCoverImg(songBean.id);
    }
    return artwork;
  }

  void playIndex(int index, MusicBean item) {
    if (playerController.playIndex.value == index &&
        controller.recordBean?.key == MusicSPManage.getCurrentPlayType().key) {
      Routes.goMusicPage();
    } else {
      onClickItem();
      playerController.playIndex.value = index;
      playerController.updataMedia(item);
      playerController.upDataPlayList(controller.recordBean);
      var playRecord = MusicSPManage.getCurrentPlayType();
      MusicSPManage.saveCurrentPlayIndex(playRecord.key, index);
    }
  }
}
