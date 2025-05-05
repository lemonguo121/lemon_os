import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lemon_tv/music/data/PlayRecordList.dart';
import 'package:lemon_tv/music/player/music_controller.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import '../../util/CommonUtil.dart';
import '../../util/widget/LoadingImage.dart';
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
  PlayListController controller = Get.put(PlayListController());
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
            isPlaying
                ? SizedBox(
                    width: 30,
                    height: 30,
                    child: AudioBarsAnimated(
                      barWidth: 2,
                      barHeight: 10,
                      color: Colors.redAccent,
                    ),
                  )
                : SizedBox.shrink(),
            // const SizedBox(width: 8),
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
                          : themeController.currentAppTheme.normalTextColor,
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
            Row(
              children: [
                Text(item.songBean.platform,style: TextStyle(fontSize: 12,color: isPlaying
                    ? themeController.currentAppTheme.selectedTextColor
                    : Colors.grey,),),
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
            )
          ],
        ),
      ),
    );
  }

  String getCover(SongBean songBean) {
    var artwork = songBean.artwork;
    var songId = songBean.id;
    if (artwork.isEmpty || !artwork.startsWith('http')) {
      return CommonUtil.getCoverImg(songId);
    }
    return artwork;
  }

}
