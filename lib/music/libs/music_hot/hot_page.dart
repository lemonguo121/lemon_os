import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/libs/music_hot/hot_controller.dart';
import 'package:lemon_tv/music/libs/music_hot/widget/hot_contentView.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:lemon_tv/util/ThemeController.dart';
import 'package:lemon_tv/util/widget/NoDataView.dart';

import '../../../routes/routes.dart';
import '../../../util/CommonUtil.dart';
import '../../../util/SubscriptionsUtil.dart';
import '../../../util/widget/NoSubscriptionView.dart';
import '../../../util/widget/SiteInvileView.dart';

class HotPage extends StatefulWidget {
  const HotPage({super.key});

  @override
  State<HotPage> createState() => _HotPageState();
}

class _HotPageState extends State<HotPage> {
  final HotController controller = Get.put(HotController());
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
      if (controller.tabs.isEmpty||controller.isLoading.value||controller.tabController==null) {
        return const Center(child: CircularProgressIndicator());
      }
      return getErrorView();
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
            onTap: () => Routes.goMusicSearchPlayer(),
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
          MaterialPageRoute(builder: (context) => HotPage()),
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
          : _buildTopicData();
    }
  }

  Widget _buildTopicData() {
    final topPadding = MediaQuery
        .of(context)
        .padding
        .top;
    return Column(
      children: [
        SizedBox(height: topPadding),
        _buildSearch(),
        Container(
          color: Colors.white,
          height: 38,
          alignment: Alignment.centerLeft,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              isScrollable: true,
              labelPadding: EdgeInsets.only(right: 20),
              // 去掉 TabBar 的默认内边距
              controller: controller.tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.redAccent,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              labelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: controller.tabs
                  .map((item) =>
                  Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(item.title),
                    ),
                  ))
                  .toList(),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: controller.tabController,
            children: controller.tabs.map((item) {
              return TopListContentView(id: item.id);
            }).toList(),
          ),
        ),
      ],
    );
  }

  void loadData() async {
    await controller.loadSite();
  }
}
