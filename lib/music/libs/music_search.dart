import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/libs/music_play.dart';
import 'package:lemon_tv/routes/routes.dart';
import '../music_http/music_http_rquest.dart';

class MusicSearchPage extends StatefulWidget {
  @override
  _MusicSearchPageState createState() => _MusicSearchPageState();
}

class _MusicSearchPageState extends State<MusicSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<dynamic> _songs = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();

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

  Future<void> _searchSongs({String? text}) async {
    final query = text ?? _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _songs = [];
      _showHistory = false;
    });

    try {
      final response = await NetworkManager().get('/search', queryParameters: {
        'query': query,
      });

      final data = response.data;
      setState(() {
        _songs = data['data'] ?? [];
        // 添加到搜索历史，不重复
        if (!_searchHistory.contains(query)) {
          _searchHistory.insert(0, query);
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
      title: Text(song['title'] ?? '未知歌曲'),
      subtitle: Text(song['artist'] ?? '未知歌手'),
      onTap: () {
        final songId = song['id'];
        final songName = song['title'];
        if (songId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MusicPlayerPage(id: songId, songName: songName),
            ),
          );
        }
      },
    );
  }

  Widget _buildHistoryItem(String keyword) {
    return ListTile(
      leading: const Icon(Icons.history),
      title: Text(keyword),
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
        title: const Text('音乐搜索'),
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
              const Expanded(child: Center(child: Text('暂无搜索结果')))
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