import 'package:flutter/material.dart';
import '../http/HttpService.dart';
import '../http/data/RealVideo.dart';
import '../detail/DetailScreen.dart';
import '../util/LoadingImage.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  RealResponseData responseData = RealResponseData(
    code: 0,
    msg: '',
    videos: [],
  );
  final HttpService _httpService = HttpService();
  List<String> _searchHistory = [];

  // 加载搜索历史记录
  Future<void> _loadSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  // 保存搜索历史记录
  Future<void> _saveSearchHistory(String query) async {
    if (query.isEmpty || _searchHistory.contains(query)) return;
    setState(() {
      _searchHistory.add(query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeAt(0); // 限制为最多10条
      }
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
  }

  // 清空所有搜索历史记录
  Future<void> _clearSearchHistory() async {
    setState(() {
      _searchHistory.clear();
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }

  // 删除单条历史记录
  Future<void> _deleteSearchHistory(int index) async {
    setState(() {
      _searchHistory.removeAt(index);
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
  }

  // 执行搜索
  Future<void> _searchVideos() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    await _saveSearchHistory(query); // 触发搜索后保存历史记录

    try {
      Map<String, dynamic> newJsonMap  = await _httpService.get(
        "",
        params: {
          "ac": "detail",
          "wd": query,
        },
      );
      setState(() {
        responseData = RealResponseData.fromJson(newJsonMap);
      });
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 30.0), // 这里设置距离顶部的间距
            // 搜索框
            Row(
              children: [
                Expanded(
                    child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "输入搜索内容",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 0.0, horizontal: 12.0), // 调整内边距使内容垂直居中
                    ),
                    style: const TextStyle(fontSize: 16.0), // 设置文本大小
                  ),
                )),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: _searchVideos,
                  child: Text("搜索"),
                ),
              ],
            ),
            // SizedBox(height: 8.0),

            // 搜索历史
            if (_searchHistory.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '搜索历史',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _clearSearchHistory,
                        child: Text("清空"),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 2.0, // 每个条目之间的水平间距
                    runSpacing: 2.0, // 每行之间的垂直间距
                    children: _searchHistory
                        .take(12) // 限制最多显示12条记录
                        .map((history) {
                      return GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchController.text = history;
                            });
                            _searchVideos();
                          },
                          onLongPress: () => _deleteSearchHistory(
                              _searchHistory.indexOf(history)),
                          child: SizedBox(
                            height: 30,
                            child: Chip(
                              label: Text(history,
                                  style: TextStyle(fontSize: 11.0)),
                              deleteIcon: Icon(Icons.close, size: 14.0),
                              onDeleted: () => _deleteSearchHistory(
                                  _searchHistory.indexOf(history)),
                            ),
                          ));
                    }).toList(),
                  ),
                ],
              ),
            SizedBox(height: 8.0),
            // 搜索结果
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      controller: ScrollController(),
                      children: [
                        ...responseData.videos.map((video) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 0.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            DetailScreen(vodId: video.vodId)));
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 80,
                                    width: 60,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4.0),
                                      child: LoadingImage(pic:video.vodPic),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10.0,
                                  ),
                                  Expanded(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        video.vodName,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(
                                        height: 2.0,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            video.vodRemarks,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(
                                            height: 8.0,
                                          ),
                                          Text(
                                            video.vodPubdate,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 2.0,
                                      ),
                                      Text(
                                        video.vodArea,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(
                                        height: 2.0,
                                      ),
                                      Text(
                                        video.typeName,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      )
                                    ],
                                  )),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
