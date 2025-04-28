import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/libs/music_controller.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 导入shared_preferences
import 'package:lemon_tv/music/libs/music_play.dart';
import 'package:lemon_tv/routes/routes.dart';
import '../../util/ThemeController.dart';
import '../../util/SubscriptionsUtil.dart';
import '../music_http/data/PluginBean.dart';
import '../music_http/music_http_rquest.dart';
import '../music_utils/MusicSPManage.dart';

class MusicSearchPage extends StatefulWidget {
  @override
  _MusicSearchPageState createState() => _MusicSearchPageState();
}

class _MusicSearchPageState extends State<MusicSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ThemeController themeController = Get.find();
  final SubscriptionsUtil _subscriptionsUtil = SubscriptionsUtil();
  MusicPlayerController playerController = Get.find();

  List<dynamic> _songs = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  bool _showHistory = false;
  int errorType = -1; //0:作为成功；1：订阅为空；2:站点不可用；
  PluginInfo? currentSite;

  @override
  void initState() {
    super.initState();
    loadSite();
    _loadSearchHistory(); // 加载本地搜索记录

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showHistory = _searchHistory.isNotEmpty;
        });
      } else {
        setState(() {
          _showHistory = false;
        });
      }
    });
  }

  void loadSite() async {
    // 第一步先检查当前是否有选择的仓库
    var currentStorehouse = MusicSPManage.getCurrentSubscription();
    if (currentStorehouse == null) {
      setState(() {
        errorType = 1;
      });
      return;
    }
    // 第二步，根据当前的仓库去请求仓库下的站点
    currentSite =
        await _subscriptionsUtil.requestMusicCurrentSites(currentStorehouse);
    if (currentSite == null) {
      setState(() {
        errorType = 2;
      });
      return;
    }
  }

  // 加载历史记录
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  // 保存历史记录
  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('search_history', _searchHistory);
  }

  Future<void> _searchSongs({String? text}) async {
    final query = text ?? _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _songs = [];
      _showHistory = false;
    });

    try {
      var currentSite = MusicSPManage.getCurrentSite();
      final response = await NetworkManager().get('/search', queryParameters: {
        'query': query,
        'plugin': currentSite?.platform ?? ""
      });

      final data = response.data;
      setState(() {
        _songs = data['data'] ?? [];
        // 添加到搜索历史，不重复
        if (!_searchHistory.contains(query)) {
          _searchHistory.insert(0, query);
          _saveSearchHistory(); // 更新历史记录
        }
      });
    } catch (e) {
      print('搜索失败：$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSongItem(dynamic song) {
    return ListTile(
      title: Text(song['title'] ?? '未知歌曲',
          style: TextStyle(
              color: themeController.currentAppTheme.normalTextColor)),
      subtitle: Text(song['artist'] ?? '未知歌手',
          style: TextStyle(
              color: themeController.currentAppTheme.normalTextColor)),
      onTap: () {
        final songId = song['id'];
        final songName = song['title'];
        if (songId != null) {
          Routes.goMusicPage();
          playerController.upDateSong(songId,songName);
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
        _controller.text = keyword;
        _searchSongs(text: keyword);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('音乐搜索',
            style: TextStyle(
                color: themeController.currentAppTheme.normalTextColor)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onSubmitted: (_) => _searchSongs(),
                    decoration: InputDecoration(
                      hintText: '输入歌曲名、歌手名或专辑名',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchSongs,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showHistory)
            Expanded(
              child: ListView.builder(
                itemCount: _searchHistory.length,
                itemBuilder: (context, index) {
                  return _buildHistoryItem(_searchHistory[index]);
                },
              ),
            )
          else if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_songs.isEmpty)
            Expanded(
                child: Center(
                    child: Text('暂无搜索结果',
                        style: TextStyle(
                            color: themeController
                                .currentAppTheme.normalTextColor))))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  return _buildSongItem(_songs[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}
