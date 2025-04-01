import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../detail/DetailScreen.dart';
import '../http/data/RealVideo.dart';
import '../mywidget/VodForamTag.dart';
import 'HistoryController.dart';
import '../util/SPManager.dart';
import '../util/CommonUtil.dart';
import '../util/LoadingImage.dart';

class PlayHistory extends StatefulWidget {
  @override
  State<PlayHistory> createState() => _PlayHistoryState();
}

class _PlayHistoryState extends State<PlayHistory> with WidgetsBindingObserver {
  final HistoryController historyController =
      Get.put(HistoryController()); // 依赖注入
  int _playIndex = 0;
  int _fromIndex = 0;
  bool _isLoading = true;
  final Map<int, String> _videoTitles = {}; // 缓存每个视频的标题
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    historyController.initList().then((_) {
      setState(() {
        _isLoading = false; // 数据加载完毕后再更新状态
      });
    });
  }

  Future<void> _getIndex(int videoId) async {
    int? progress = await SPManager.getIndex(videoId) ?? 0;
    var fromIndex = await SPManager.getFromIndex(videoId) ?? 0;
    setState(() {
      _playIndex = progress;
      _fromIndex = fromIndex;
    });
  }

  Future<void> getVideoRec(RealVideo video) async {
    try {
      await _getIndex(video.vodId);
      var playList = CommonUtil.getPlayListAndForm(video).playList;
      setState(() {
        _videoTitles[video.vodId] =
        (_fromIndex >= 0 && _fromIndex < playList.length)
            ? playList[_fromIndex][_playIndex]['title']!
            : "";
      });
    } catch (e) {
      setState(() {
        _videoTitles[video.vodId] = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var isVertical = CommonUtil.isVertical(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("历史记录"),
        actions: [
          IconButton(
            onPressed: () {
              historyController.cleanHistory();
              setState(() {});
              CommonUtil.showToast("清理成功");
            },
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      body: Obx(() => _buildBody(isVertical)),
    );
  }

  Widget _buildBody(bool isVertical) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (historyController.historyList.isEmpty) {
      return const Center(
        child: Text('暂无历史记录'),
      );
    } else {
      return _buildGrid(isVertical);
    }
  }

  Widget _buildGrid(bool isVertical) {
    return Obx(() => GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isVertical ? 3 : 6, // 一行三个
            crossAxisSpacing: 8.0, // 水平方向间距
            mainAxisSpacing: 8.0, // 垂直方向间距
            childAspectRatio: 0.75, // 调整宽高比
          ),
          itemCount: historyController.historyList.length,
          itemBuilder: (context, index) {
            return _buildGridItem(index);
          },
        ));
  }

  Widget _buildGridItem(int index) {
    var historyList = historyController.historyList;
    var realVideo = historyList[index];
    // print("_buildGridItem   title = ${realVideo.typeName}  domain = ${realVideo.subscriptionDomain} ");
    // 确保每个视频的标题加载完成
    if (!_videoTitles.containsKey(realVideo.vodId)) {
      getVideoRec(realVideo);
    }
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(
                vodId: realVideo.vodId,
                site: realVideo.site,
              ), // 动态传递vodId
            ));
      },
      onLongPress: () {
        historyController.removeHistoryItem(realVideo);
        CommonUtil.showToast("删除成功");
      },
      child: Stack(
        children: [
          // 封面图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LoadingImage(
              pic: realVideo.vodPic,
            ),
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
                    realVideo.vodArea, // 视频标题
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _videoTitles[realVideo.vodId] ?? "",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    realVideo.vodName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          ),
          VodForamTag(realVideo: realVideo)
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
