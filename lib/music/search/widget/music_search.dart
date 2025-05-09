import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/data/SongBean.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:lemon_tv/routes/routes.dart';
import 'package:lemon_tv/util/SubscriptionsUtil.dart';

import '../../../../util/ThemeController.dart';
import '../../../util/widget/NoDataView.dart';
import '../../player/music_controller.dart';
import '../search_controll.dart';

class MusicSearchPage extends StatefulWidget {
  @override
  _MusicSearchPageState createState() => _MusicSearchPageState();
}

class _MusicSearchPageState extends State<MusicSearchPage> {
  final TextEditingController _editController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ThemeController themeController = Get.find();

  MusicPlayerController playerController = Get.find();
  final SearchControll controller = Get.put(SearchControll());

  int errorType = -1; //0:作为成功；1：订阅为空；2:站点不可用；

  @override
  void initState() {
    super.initState();
    controller.loadSearchHistory(); // 加载本地搜索记录
    controller.pluginList.value = SubscriptionsUtil().pluginsList;
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        controller.showHistory.value = controller.searchHistory.isNotEmpty;
      } else {
        controller.showHistory.value = false;
      }
    });
  }

  Widget _buildSongItem(dynamic song) {
    var songBean = SongBean.fromJson(song);
    return ListTile(
      title: Text(songBean.title ?? '未知歌曲',
          style: TextStyle(
              color: themeController.currentAppTheme.normalTextColor)),
      subtitle: Text(songBean.artist ?? '未知歌手',
          style: TextStyle(
              color: themeController.currentAppTheme.normalTextColor)),
      onTap: () {
        if (songBean.id.isNotEmpty) {
          playerController.upDataSong(songBean);
          MusicSPManage.saveCurrentPlayIndex(MusicSPManage.history, 0);
          Routes.goMusicPage();
        }
      },
    );
  }

  Widget _buildHistoryItem(String keyword) {
    return ListTile(
      leading:  Icon(Icons.history,color: themeController.currentAppTheme.normalTextColor.withOpacity(0.3),),
      title: Text(keyword,
          style: TextStyle(
              color: themeController.currentAppTheme.normalTextColor)),
      onTap: () {
        _editController.text = keyword;
        controller.searchMusic(keyword);
      },
    );
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    Get.delete<SearchController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(
                color: themeController.currentAppTheme.normalTextColor),
            title: Text('音乐搜索',
                style: TextStyle(
                    color: themeController.currentAppTheme.normalTextColor)),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child:  Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _editController,
                      focusNode: _focusNode,
                      onSubmitted: (value) => controller.searchMusic(_editController.text),
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: themeController.currentAppTheme.selectedTextColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        hintText: "输入歌曲名、歌手名或专辑名",
                        hintStyle: TextStyle(
                            color: themeController.currentAppTheme.contentColor),
                        prefixIcon: Icon(
                          Icons.search,
                          color: themeController.currentAppTheme.contentColor,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey, // 设置你想要的颜色
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey, // 设置你想要的颜色
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding:
                        EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
                      ),
                      style: TextStyle(
                          fontSize: 16.0,
                          color: themeController.currentAppTheme.titleColr),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 22.h,
              ),
              _buildSiteList(),
              SizedBox(
                height: 22.h,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 50.h,
                child: Row(
                  children: [
                    _buildSearchType('音乐', 'music'),
                    _buildSearchType('专辑', 'album'),
                    _buildSearchType('作者', 'artist'),
                    _buildSearchType('歌单', 'sheet'),
                  ],
                ),
              ),
              SizedBox(
                height: 10.h,
              ),
              if (controller.showHistory.value)
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.searchHistory.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryItem(controller.searchHistory[index]);
                    },
                  ),
                )
              else if (controller.isLoading.value)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (controller.songs.isEmpty)
                Expanded(
                  child: NoDataView(reload: goSearch, errorTips: '暂无搜索结果'),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.songs.length,
                    itemBuilder: (context, index) {
                      return _buildSongItem(controller.songs[index]);
                    },
                  ),
                ),
            ],
          ),
        ));
  }

  Widget _buildSearchType(String content, String type) {
    final isSelected = controller.searchType.value == type;
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected
              ? themeController.currentAppTheme.selectedTextColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeController.currentAppTheme.selectedTextColor.withOpacity(0.4),
                    blurRadius: 16.r,
                    offset: Offset(0, 6.h),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: InkWell(
            onTap: () {
              controller.searchType.value = type;
              controller.searchMusic(_editController.text);
            },
            child: Text(
              content,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : themeController.currentAppTheme.normalTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  goSearch() {
    controller.searchMusic(_editController.text);
  }

  Widget _buildSiteList() {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.pluginList.value.length,
        itemBuilder: (context, index) {
          var plugin = controller.pluginList.value[index];
          final isSelected = controller.currentSite.value == plugin.platform;
          return InkWell(
            onTap: () {
              controller.currentSite.value = plugin.platform;
              controller.searchMusic(_editController.text);
              // 不知道这里为什么触发不了obx的刷新，只能使用setState代替刷新了
              setState(() {

              });
            },
            child: SizedBox(
              width: 120.w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isSelected
                      ? themeController.currentAppTheme.selectedTextColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: themeController.currentAppTheme.selectedTextColor.withOpacity(0.4),
                            blurRadius: 16.r,
                            offset: Offset(0, 6.h),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    plugin.name,
                    style: TextStyle(
                      fontSize: 28.sp,
                      color: isSelected
                          ? Colors.white
                          : themeController.currentAppTheme.normalTextColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
