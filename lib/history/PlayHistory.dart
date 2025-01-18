import 'package:flutter/material.dart';

import '../detail/DetailScreen.dart';
import '../http/data/RealVideo.dart';
import '../player/SPManager.dart';
import '../util/CommonUtil.dart';
import '../util/LoadingImage.dart';

class PlayHistory extends StatefulWidget {
   PlayHistory({super.key});

  @override
  State<PlayHistory> createState() => _PlayHistoryState();
}

class _PlayHistoryState extends State<PlayHistory> with WidgetsBindingObserver {
  List<RealVideo>? _historyList;
  int _playIndex = 0;
  bool _isLoading = true;
  Map<int, String> _videoTitles = {}; // 缓存每个视频的标题
  @override
  void initState() {
    super.initState();
    _loadHistoryList();
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

      if (_playIndex != null &&
          _playIndex >= 0 &&
          _playIndex < playList.length) {
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
      body: _buildBody(),
    );
  }

  Future<void> _refreshHistoryList() async {
    setState(() => _isLoading = true);
    await _loadHistoryList();
  }

  Future<List<RealVideo>> _getHistoryList() {
    return SPManager.getHistoryList();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_historyList == null || _historyList!.isEmpty) {
      return const Center(
        child: Text('暂无历史记录'),
      );
    } else {
      return _buildGrid();
    }
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 一行三个
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
    // 确保每个视频的标题加载完成
    if (!_videoTitles.containsKey(realVideo.vodId)) {
      getVideoRec(realVideo);
    }
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetailScreen(vodId: realVideo.vodId), // 动态传递vodId
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
                    realVideo.vodName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _videoTitles[realVideo.vodId] ?? "", // 视频标题
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
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
}
