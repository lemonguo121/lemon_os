import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/data/SongBean.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:lemon_tv/routes/routes.dart';

import '../../../../util/ThemeController.dart';
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
      leading: const Icon(Icons.history),
      title: Text(keyword,
          style: TextStyle(
              color: themeController.currentAppTheme.normalTextColor)),
      onTap: () {
        print("onTap keyword = $keyword");
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
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: themeController.currentAppTheme.normalTextColor),
        title: Text('音乐搜索',
            style: TextStyle(
                color: themeController.currentAppTheme.normalTextColor)),
        centerTitle: true,
      ),
      body: Obx(() => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _editController,
                        focusNode: _focusNode,
                        style: TextStyle(
                            fontSize: 16.0,
                            color: themeController.currentAppTheme.titleColr),
                        onSubmitted: (_) =>
                            controller.searchMusic(_editController.text),
                        decoration: InputDecoration(
                          hintText: '输入歌曲名、歌手名或专辑名',
                          hintStyle: TextStyle(
                              color: themeController.currentAppTheme.contentColor),
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: (() {
                              controller.searchMusic(_editController.text);
                            }),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildSearchType('音乐', 'music'),
                  _buildSearchType('专辑', 'album'),
                  _buildSearchType('作者', 'artist'),
                  _buildSearchType('歌单', 'sheet'),
                ],
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
                    child: Center(
                        child: Text('暂无搜索结果',
                            style: TextStyle(
                                color: themeController
                                    .currentAppTheme.normalTextColor))))
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
          )),
    );
  }

  Widget _buildSearchType(String content, String type) {
    return Expanded(
        child: InkWell(
      onTap: (() {
        controller.searchType.value = type;
        controller.searchMusic(_editController.text);
      }),
      child: Text(
        content,
        style:
            TextStyle(color: themeController.currentAppTheme.normalTextColor),
      ),
    ));
  }
}
