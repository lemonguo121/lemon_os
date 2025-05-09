import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        padding: EdgeInsets.symmetric(vertical: 16.r),
        child: InkWell(
          onTap: () => playIndex(index, item),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              isPlaying
                  ? SizedBox(
                      width: 40.w,
                      height: 30.h,
                      child: AudioBarsAnimated(
                        barWidth: 4.w,
                        barHeight: 25.h,
                        color: Colors.redAccent,
                      ),
                    )
                  : const SizedBox.shrink(), // 保持结构对齐
              SizedBox(width: 6.w),
              SizedBox(
                width: 80.r,
                height: 80.r,
                child: ClipOval(
                  child: LoadingImage(pic: getCover(item.songBean)),
                ),
              ),
              SizedBox(width: 10.h),
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
                  isNeedDelete
                      ? InkWell(
                          onTap: () {
                            onDelete(item);
                            if (controller.recordBean?.key ==
                                MusicSPManage.getCurrentPlayType().key) {
                              if (index < playerController.playIndex.value) {
                                playerController.playIndex.value--;
                                MusicSPManage.saveCurrentPlayIndex(
                                    controller.recordBean?.key ?? '',
                                    playerController.playIndex.value);
                              } else if (index ==
                                  playerController.playIndex.value) {
//                    ************这里一定要区分是播放列表数据controller.playList，还是播放器此时的数据playerController.playList，弄混了就导致对应的数据无法刷新  **************
                                if (controller.playList.value.isNotEmpty) {
                                  playerController
                                      .updataMedia(controller.playList[index]);
                                } else {
                                  playerController.updataMedia(
                                      playerController.playList[index]);
                                }
//                    ************这里一定要区分是播放列表数据controller.playList，还是播放器此时的数据playerController.playList，弄混了就导致对应的数据无法刷新  **************
                                playerController.playIndex.value = index;
                                MusicSPManage.saveCurrentPlayIndex(
                                    controller.recordBean?.key ?? '', index);
                              }
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child:
                                Icon(Icons.close, color: Colors.red, size: 18),
                          ),
                        )
                      : SizedBox.shrink(),
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
