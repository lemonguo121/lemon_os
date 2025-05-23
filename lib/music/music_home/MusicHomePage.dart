import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/music_home/music_home_controller.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:lemon_tv/music/player/music_controller.dart';
import 'package:lemon_tv/util/MusicCacheUtil.dart';
import 'package:lemon_tv/util/ThemeController.dart';
import 'package:lemon_tv/util/widget/NoDataView.dart';

import '../../../mywidget/MyLoadingIndicator.dart';
import '../../../routes/routes.dart';
import '../../../util/CommonUtil.dart';
import '../../../util/SubscriptionsUtil.dart';
import '../../../util/widget/NoSubscriptionView.dart';
import '../../../util/widget/SiteInvileView.dart';
import '../../main.dart';
import '../../util/widget/LoadingImage.dart';
import '../data/MusicBean.dart';
import '../data/PlayRecordList.dart';
import '../player/widget/music_mini_bar.dart';

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final MusicHomeController controller = Get.find();
  final MusicPlayerController playerController = Get.find();
  final ThemeController themeController = Get.find();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
      controller.getRordList();
      MusicCacheUtil.ensureStoragePermission();
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        playerController.adjustVolume(-1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        playerController.adjustVolume(1);
      }
    } else if (event is RawKeyUpEvent) {
      // 键盘抬起时的事件
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Obx(() {
        var isVertical = CommonUtil.isVertical();
        return Scaffold(
          body: Column(
            children: [
              SizedBox(height: isVertical ? 55.0 : 40),
              _buildSearch(),
              SizedBox(height: 16.0.h),
              Expanded(child: getErrorView()),
              _buildMiniBar(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        const SizedBox(width: 12.0),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true, // 让弹窗自适应
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                Future.delayed(Duration.zero, () {
                  if (controller.currentSite.value != null) {}
                });
                var dialogSize;
                if (CommonUtil.isVertical()) {
                  dialogSize = CommonUtil.getScreenWidth(context) * 9 / 10;
                } else {
                  dialogSize = CommonUtil.getScreenHeight(context) * 9 / 10;
                }

                return Container(
                  padding: EdgeInsets.all(16),
                  height: dialogSize * 7 / 8, // 固定弹窗高度
                  width: dialogSize,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("请选择首页数据源",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      SizedBox(height: 16),
                      // 将 GridView 放入 SingleChildScrollView 或 Expanded
                      Expanded(
                        child: GridView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          // 防止 GridView 超出范围
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8.0,
                            crossAxisSpacing: 8.0,
                            mainAxisExtent: 30,
                          ),
                          itemCount: SubscriptionsUtil().pluginsList.length,
                          itemBuilder: (context, index) {
                            return _buildSiteGridItem(index);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public,
                  size: 20,
                  color: themeController.currentAppTheme.selectedTextColor),
              const SizedBox(width: 4),
              SizedBox(
                width: 40,
                child: Text(
                  controller.currentSite.value.name.isEmpty
                      ? '未订阅'
                      : controller.currentSite.value.name,
                  style: TextStyle(
                      fontSize: 12,
                      color: themeController.currentAppTheme.titleColr),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: InkWell(
            onTap: () => Routes.goMusicSearchPage(),
            child: Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: themeController.currentAppTheme.backgroundColor,
                border: Border.all(
                    color: themeController.currentAppTheme.selectedTextColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.search,
                      color: themeController.currentAppTheme.contentColor),
                  const SizedBox(width: 8.0),
                  Text("输入搜索内容",
                      style: TextStyle(
                          fontSize: 16.0,
                          color: themeController.currentAppTheme.contentColor)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
      ],
    );
  }

  Widget _buildSiteGridItem(int index) {
    var selectStorehouse = controller.subscriptionsUtil.pluginsList[index];
    var siteName = selectStorehouse.name;

    return GestureDetector(
      onTap: () async {
        controller.selecteSitedIndex.value = index;
        MusicSPManage.saveCurrentSite(
            controller.subscriptionsUtil.pluginsList[index]);
        setState(() {});
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: siteName == (controller.currentSite.value.name ?? "")
                ? Colors.blueAccent
                : Colors.transparent,
            border: Border.all(color: Colors.black45),
            borderRadius: BorderRadius.circular(30.0)),
        child: Text(
          siteName,
          style: TextStyle(
              color: siteName == (controller.currentSite.value.name ?? "")
                  ? Colors.white
                  : Colors.black,
              fontSize: 14.0,
              fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget getErrorView() {
    if (controller.errorType.value == 1) {
      // 订阅为空
      return NoSubscriptionView(onAddSubscription: Routes.goPluginPage);
    } else {
      return _buildTopicWidget();
    }
  }

  void loadData() async {
    await controller.loadSite();
  }

  Widget _buildTopicWidget() {
    return Expanded(child: _buildweidget());
  }

  Widget _buildGridItem(int index) {
    var tabs = controller.tabs;
    var tab = tabs[index];

    return GestureDetector(
      onTap: () {
        Routes.goHotDetaiPage(tab);
      },
      child: Stack(
        children: [
          // 封面图片
          ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: LoadingImage(
                pic: CommonUtil.getCoverImg(tab.id),
              )),
          // 覆盖层显示文字
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter, // 渐变起点（顶部）
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05), // 顶部完全透明
                        Colors.black.withOpacity(0.9), // 底部半透明黑色
                      ]),
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0))),
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 8.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tab.title,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayRecordList() {
    PlayRecordList playRecordType = MusicSPManage.getCurrentPlayType();
    return ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: controller.recordList.value.length,
        itemBuilder: (context, index) {
          var record = controller.recordList.value[index];
          List<MusicBean> playList = MusicSPManage.getPlayList(record.key);
          return GestureDetector(
            behavior: HitTestBehavior.translucent, // ✅ 允许空白区域也响应点击
            onTap: () => {Routes.goPlayListPage(record)},
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120.r,
                          height: 90.r,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0.r),
                              child: LoadingImage(
                                pic: CommonUtil.getCoverImg(record.key),
                              )),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                record.name,
                                style: TextStyle(
                                  color: record.key == playRecordType.key
                                      ? themeController
                                          .currentAppTheme.selectedTextColor
                                      : themeController
                                          .currentAppTheme.normalTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${playList.length}首',
                                style: TextStyle(
                                  color: record.key == playRecordType.key
                                      ? themeController
                                          .currentAppTheme.selectedTextColor
                                      : Colors.grey,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDeleteRecord(record)
                ],
              ),
            ),
          );
        });
  }

  _buildMiniBar() {
    return playerController.playList.isNotEmpty
        ? MiniMusicPlayerBar()
        : const SizedBox.shrink();
  }

  Widget _buildHotWidget() {
    var hotViewHeight = 290.h;
    var isVertical = CommonUtil.isVertical();
    if (controller.isLoading.value) {
      return SizedBox(
        height: hotViewHeight,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (controller.errorType.value == 2) {
      // 站点不可用
      return SizedBox(
        height: hotViewHeight,
        child: SiteInvileView(reload: loadData),
      );
    }
    return controller.tabs.isEmpty
        // return true
        ? SizedBox(
            height: hotViewHeight,
            child: Center(
              child: NoDataView(reload: loadData, errorTips: ''),
            ),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '推荐榜单',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              themeController.currentAppTheme.normalTextColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        Routes.goHotListPage();
                      },
                      child: Text(
                        '',
                        // '全部 >',
                        style: TextStyle(
                            fontSize: 14,
                            color: themeController
                                .currentAppTheme.normalTextColor),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 16.h,
              ),
              isVertical
                  ? SizedBox(
                      height: hotViewHeight,
                      child: buildHotGrid(isVertical),
                    )
                  : Expanded(
                      child: buildHotGrid(isVertical),
                    ),
            ],
          );
  }

  Widget _buildDeleteRecord(PlayRecordList record) {
    if (record.canDelete) {
      return IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.delete_outlined,
          color: Colors.redAccent,
          size: 35.r,
        ),
        onPressed: () {
          controller.recordList.value = controller.recordList
              .where((item) => item.key != record.key)
              .toList();
          MusicSPManage.saveRecordList(controller.recordList.value);
          MusicSPManage.clearAllSongs(record.key);
        },
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildweidget() {
    var isVertical = CommonUtil.isVertical();
    return isVertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 榜单
              _buildHotWidget(),
              SizedBox(
                height: 32.h,
              ),
              // 播放列表
              _buildPlayerWidget()
            ],
          )
        : Expanded(
            child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 榜单
              Expanded(child: _buildHotWidget()),
              // 播放列表
              _buildPlayerWidget()
            ],
          ));
  }

  Widget _buildPlayerWidget() {
    return Expanded(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '我的歌单',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeController.currentAppTheme.normalTextColor,
            ),
          ),
        ),
        Expanded(
          child: _buildPlayRecordList(),
        ),
        SizedBox(
          height: 6.h,
        )
      ],
    ));
  }

  Widget buildHotGrid(bool isVertical) {
    return GridView.builder(
      scrollDirection: isVertical ? Axis.horizontal : Axis.vertical,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isVertical ? 2 : 3, // 显示两行
        mainAxisSpacing: 8.0, // item 横向间距
        crossAxisSpacing: 8.0, // item 纵向间距
        childAspectRatio: isVertical ? 1 : 1.2, // 宽高比，自行调整
      ),
      itemCount: controller.tabs.length,
      itemBuilder: (context, index) {
        return SizedBox(
          width: isVertical ? 140.r : 105.w, // 固定宽度
          height: isVertical ? 140.r : 105.h,
          child: _buildGridItem(index),
        );
      },
    );
  }
}
