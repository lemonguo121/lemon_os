import 'package:flutter/material.dart';

import '../detail/DetailScreen.dart';
import '../http/data/RealVideo.dart';
import '../mywidget/VodForamTag.dart';
import '../util/SPManager.dart';
import '../util/CommonUtil.dart';
import '../util/LoadingImage.dart';

class PlayHistory extends StatefulWidget {
  const PlayHistory({super.key});

  @override
  State<PlayHistory> createState() => _PlayHistoryState();
}

class _PlayHistoryState extends State<PlayHistory> with WidgetsBindingObserver {
  List<RealVideo>? _historyList;
  int _playIndex = 0;
  bool _isLoading = true;
  final Map<int, String> _videoTitles = {}; // 缓存每个视频的标题
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistoryList();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshHistoryList(); // 应用恢复时刷新数据
    }
  }

  Future<void> _loadHistoryList() async {
    try {
      final list = await _getHistoryList();
      setState(() {
        _historyList = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        print("lemon Error = ${e.toString()}");
        _isLoading = false;
        CommonUtil.showToast("加载失败");
      });
    }
  }

  Future<void> _getIndex(int videoId) async {
    int? progress = await SPManager.getIndex(videoId);
    if (progress != null) {
      setState(() {
        _playIndex = progress;
      });
    }
  }

  Future<void> getVideoRec(RealVideo video) async {
    try {
      // 异步获取播放索引
      await _getIndex(video.vodId);
      var playList = CommonUtil.getPlayList(video);

      if (_playIndex >= 0 && _playIndex < playList.length) {
        setState(() {
          _videoTitles[video.vodId] = playList[_playIndex]['title']!;
        });
      } else {
        setState(() {
          _videoTitles[video.vodId] = "";
        });
      }
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
              SPManager.clearHistory();
              _refreshHistoryList();
              CommonUtil.showToast("清理成功");
            },
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      body: _buildBody(isVertical),
    );
  }

  Future<void> _refreshHistoryList() async {
    setState(() => _isLoading = true);
    await _loadHistoryList();
  }

  Future<List<RealVideo>> _getHistoryList() {
    return SPManager.getHistoryList();
  }

  Widget _buildBody(bool isVertical) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_historyList == null || _historyList!.isEmpty) {
      return const Center(
        child: Text('暂无历史记录'),
      );
    } else {
      return _buildGrid(isVertical);
    }
  }

  Widget _buildGrid(bool isVertical) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isVertical ? 3 : 6, // 一行三个
        crossAxisSpacing: 8.0, // 水平方向间距
        mainAxisSpacing: 8.0, // 垂直方向间距
        childAspectRatio: 0.75, // 调整宽高比
      ),
      itemCount: _historyList!.length,
      itemBuilder: (context, index) {
        return _buildGridItem(index);
      },
    );
  }

  Widget _buildGridItem(int index) {
    var realVideo = _historyList![index];
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
            )).then((value) => _refreshHistoryList());
      },
      onLongPress: () {
        SPManager.removeSingleHistory(realVideo);
        setState(() {
          _loadHistoryList();
          CommonUtil.showToast("删除成功");
        });
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
