import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/music_home/music_home_controller.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:lemon_tv/music/player/music_controller.dart';
import 'package:lemon_tv/util/ThemeController.dart';
import 'package:lemon_tv/util/widget/NoDataView.dart';

import '../../../mywidget/MyLoadingIndicator.dart';
import '../../../routes/routes.dart';
import '../../../util/CommonUtil.dart';
import '../../../util/SubscriptionsUtil.dart';
import '../../../util/widget/NoSubscriptionView.dart';
import '../../../util/widget/SiteInvileView.dart';
import '../data/MusicBean.dart';
import '../data/PlayRecordList.dart';
import '../player/widget/music_mini_bar.dart';

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final MusicHomeController controller = Get.put(MusicHomeController());
  final MusicPlayerController playerController = Get.find();
  final ThemeController themeController = Get.find();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Column(children: [
          MyLoadingIndicator(isLoading: controller.isLoading.value)
        ]);
      }
      var isVertical = CommonUtil.isVertical(context);
      return Scaffold(
        body: Column(
          children: [
            SizedBox(height: isVertical ? 55.0 : 40),
            _buildSearch(),
            Expanded(child: getErrorView()),
            _buildMiniBar()
          ],
        ),
      );
    });
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
                  if (controller.currentSite.value != null) {
                    // int selectedIndex = _subscriptionsUtil.selectStorehouse
                    //     .indexWhere((e) => e.name == currentSite!.name);
                    // if (selectedIndex != -1) {
                    //   _scrollToSelectedItem(selectedIndex);
                    // }
                  }
                });
                var dialogSize;
                if (CommonUtil.isVertical(context)) {
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
              Icon(Icons.menu,
                  size: 30,
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
          MaterialPageRoute(builder: (context) => MusicHomePage()),
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
    } else if (controller.errorType.value == 2) {
      // 站点不可用
      return SiteInvileView(reload: loadData);
    } else {
      return controller.tabs.isEmpty
          ? NoDataView(
              reload: loadData,
            )
          : _buildTopicWidget();
    }
  }

  void loadData() async {
    await controller.loadSite();
  }

  Widget _buildTopicWidget() {
    if (controller.tabs.isEmpty ||
        controller.isLoading.value ||
        controller.tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 6.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '推荐榜单',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeController.currentAppTheme.selectedTextColor),
              ),
              GestureDetector(
                onTap: () {
                  Routes.goHotListPage();
                },
                child: Text(
                  '全部',
                  style: TextStyle(
                      fontSize: 14,
                      color: themeController.currentAppTheme.normalTextColor),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200, // 高度 = 每个 item 的高度 × 2 + 间距
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 显示两行
              mainAxisSpacing: 8.0, // item 横向间距
              crossAxisSpacing: 8.0, // item 纵向间距
              childAspectRatio: 1, // 宽高比，自行调整
            ),
            itemCount: controller.tabs.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 90, // 固定宽度
                height: 90,
                child: _buildGridItem(index),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
          child: Text(
            '我的歌单',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeController.currentAppTheme.selectedTextColor),
          ),
        ),
        _buildPlayRecordList()
      ],
    );
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
            child: Image(image: AssetImage('assets/music/record.png')),
          ),
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
    List<PlayRecordList> list = MusicSPManage.getRecordList();
    print('_buildPlayRecordList = ${list.length}');
    return ListView.builder(
        shrinkWrap: true,
        itemCount: list.length,
        itemBuilder: (context, index) {
          var record = list[index];
          List<MusicBean> playList = MusicSPManage.getPlayList(record.name);
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () => {Routes.goPlayListPage()},
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    record.name,
                    style: TextStyle(
                        color: themeController.currentAppTheme.normalTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  SizedBox(
                    width: 4.0.w,
                  ),
                  Text(
                    '(${playList.length})',
                    style: TextStyle(
                        color: themeController.currentAppTheme.normalTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  )
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
}
