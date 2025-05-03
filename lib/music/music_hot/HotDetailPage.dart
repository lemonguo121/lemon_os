import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/data/SongBean.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import '../../routes/routes.dart';
import '../../util/CommonUtil.dart';
import '../../util/widget/LoadingImage.dart';
import '../../util/widget/NoDataView.dart';
import '../data/MusicBean.dart';
import '../data/PlayRecordList.dart';
import '../music_home/music_home_controller.dart';
import '../music_utils/MusicSPManage.dart';
import '../player/music_controller.dart';
import '../player/widget/music_yinfu.dart';
import 'hot_model/hot_Model.dart';

class HotDetailPage extends StatefulWidget {
  const HotDetailPage({super.key});

  @override
  State<HotDetailPage> createState() => _HotDetailPageState();
}

class _HotDetailPageState extends State<HotDetailPage> {
  TopListItem? topListItem;
  final MusicHomeController controller = Get.find();
  final MusicPlayerController playerController = Get.find();
  final ThemeController themeController = Get.find();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    topListItem = args['topListItem'];
    controller.checkIsColled(topListItem);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      load();
    });
  }

  void load() {
    controller.getHotList(id: topListItem?.id ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
              color: themeController.currentAppTheme.normalTextColor),
          title: Text('榜单',
              style: TextStyle(
                  color: themeController.currentAppTheme.normalTextColor)),
          centerTitle: true,
        ),
        body: _buildContentWidget()));
  }

  Widget _buildContentWidget() {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.subModel.value.musicList.isEmpty) {
      return NoDataView(reload: load);
    }
    return _buildInfoAndListWidget();
  }

  Widget _buildInfoAndListWidget() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHotInfo(),
            SizedBox(height: 32.h),
            Row(
              children: [
                Expanded(
                    child: Text(
                  '播放列表',
                  style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: themeController.currentAppTheme.normalTextColor),
                )),
                InkWell(
                  onTap: () {
                    bool exists = controller.recordList
                        .any((e) => e.key == topListItem?.id);
                    if (exists) {
                      CommonUtil.showToast('列表已存在');
                    } else {
                      var playrecord = PlayRecordList(
                          name: topListItem?.title ?? "",
                          key: topListItem?.id ?? "",
                          canDelete: true);
                      var recordList = controller.recordList.value;
                      recordList.add(playrecord);
                      var musicList = controller.subModel.value.musicList;
                      List<MusicBean> musicPlayList = [];
                      for (int i = 0; i < musicList.length; i++) {
                        final item = musicList[i];
                        var musicBean =
                            MusicBean(songBean: item, rawLrc: [], url: '');
                        musicPlayList.add(musicBean);
                      }
                      MusicSPManage.savePlayList(
                          musicPlayList, topListItem?.id ?? "");
                      controller.isColled.value = true;
                      controller.recordList.value = recordList;
                      MusicSPManage.saveRecordList(recordList);
                      controller.recordList.refresh();
                    }
                  },
                  child: Text(
                    controller.isColled.value ? '已添加' : '添加列表',
                    style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: controller.isColled.value
                            ? Colors.red
                            : themeController.currentAppTheme.normalTextColor),
                  ),
                )
              ],
            ),
            SizedBox(height: 28.h),
            ..._buildSongList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHotInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180.r,
          height: 180.r,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LoadingImage(
              pic: CommonUtil.getCoverImg(topListItem?.id ?? ""),
            ),
          ),
        ),
        SizedBox(width: 24.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topListItem?.title ?? '无标题',
                style: TextStyle(
                    fontSize: 42.sp,
                    fontWeight: FontWeight.bold,
                    color: themeController.currentAppTheme.normalTextColor),
              ),
              const SizedBox(height: 8),
              Text(
                topListItem?.description ?? '暂无描述',
                style: TextStyle(
                    fontSize: 28.sp,
                    color: themeController.currentAppTheme.contentColor),
              ),
              const SizedBox(height: 6),
              Text(
                '共 ${controller.subModel.value.musicList.length} 首',
                style: TextStyle(
                    fontSize: 22.sp,
                    color: themeController.currentAppTheme.selectedTextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSongList() {
    final musicList = controller.subModel.value.musicList;

    return musicList.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return GestureDetector(
        onTap: () {
          if (item.id != null) {
            playerController.upDataSong(item);
            Routes.goMusicPage();
          }
        },
        child: playListCell(item, index),
      );
    }).toList();
  }

  Widget playListCell(SongBean item, int index) {
    final bool isPlaying = item.id == playerController.songBean.value.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          playerController.playIndex.value = index;
          playerController.upDataSong(item);
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
                : const SizedBox.shrink(),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              height: 36,
              child: ClipOval(
                child: LoadingImage(pic: getCover(item)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.isNotEmpty ? item.title : (item.artist ?? ""),
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
                  if (item.artist != null)
                    Text(
                      item.artist!,
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
                controller.subModel.value.musicList.remove(item);
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

  String getTitle(SongBean songBean) {
    // var songBean = songBean.value;
    var title = songBean.title;
    var artist = songBean.artist;
    if (artist.isEmpty && title.isEmpty) {
      return '未知歌曲';
    }
    return '$title $artist';
  }

  String getCover(SongBean songBean) {
    // var songBean = this.songBean.value;
    var artwork = songBean.artwork;
    var id = songBean.id;
    if (artwork.isEmpty || !artwork.startsWith('http')) {
      return CommonUtil.getCoverImg(id);
    }
    return artwork;
  }
}
