import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/data/SongBean.dart';
import 'package:lemon_tv/music/playlist/PlayListController.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import '../../routes/routes.dart';
import '../../util/CommonUtil.dart';
import '../../util/widget/LoadingImage.dart';
import '../../util/widget/NoDataView.dart';
import '../common/PlayListCell.dart';
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
  final PlayListController playListController = Get.find();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    topListItem = args['topListItem'];
    controller.checkIsColled(topListItem);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      load();
      playListController.recordBean = PlayRecordList(
          name: topListItem?.title ?? '未知列表',
          key: topListItem?.id??'topListItem',
          canDelete: true);
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
    if (controller.isLoading2.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.subModel.value.musicList.isEmpty) {
      return NoDataView(
        reload: load,
        errorTips: '暂无数据，点击刷新',
      );
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
            _buildHotInfo(context),
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
                          name: topListItem?.title ?? "未知列表",
                          key: topListItem?.id ?? "topListItem",
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
                  pic: CommonUtil.getCoverImg(topListItem?.id ?? ""),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topListItem?.title ?? '无标题',
                    style: TextStyle(
                        fontSize: constraints.maxWidth * 0.05, // 5%宽度作为字体大小
                        fontWeight: FontWeight.bold,
                        color: themeController.currentAppTheme.normalTextColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topListItem?.description ?? '暂无描述',
                    style: TextStyle(
                        fontSize: constraints.maxWidth * 0.035,
                        color: themeController.currentAppTheme.contentColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '共 ${controller.subModel.value.musicList.length} 首',
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

  List<Widget> _buildSongList() {
    final musicList = controller.subModel.value.musicList;
    List<MusicBean> list = [];
    for (var songBean in musicList) {
      list.add(MusicBean(songBean: songBean, rawLrc: [], url: ''));
    }
    return list.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return PlayListCell(
          item: item,
          index: index,
          isBottomSheet: false,
          isNeedDelete: false,
          onDelete: deleteItem,
          onClickItem: clickItem);
    }).toList();
  }

  void deleteItem(MusicBean value) {}

  void clickItem() {
    var musicList = controller.subModel.value.musicList;
    List<MusicBean> musicPlayList = [];
    for (int i = 0; i < musicList.length; i++) {
      final item = musicList[i];
      var musicBean = MusicBean(songBean: item, rawLrc: [], url: '');
      musicPlayList.add(musicBean);
    }
    MusicSPManage.savePlayList(musicPlayList, topListItem?.id ?? "");
  }
}
