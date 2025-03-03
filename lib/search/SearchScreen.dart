import 'package:flutter/material.dart';
import '../http/HttpService.dart';
import '../http/data/RealVideo.dart';
import '../detail/DetailScreen.dart';
import '../util/LoadingImage.dart';
import '../util/SPManager.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  final HttpService _httpService = HttpService();
  List<String> _searchHistory = [];
  Map<String, RealResponseData> _searchResults = {}; // 以站点名存储不同站点的搜索结果
  List<Map<String, String>> _subscriptions = [];
  late RealResponseData selectResponseData;
  String selectSite = ""; // 当前选择的站点名
  bool _hasSearch = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadSubscriptions();
  }

  // 加载已订阅站点
  Future<void> _loadSubscriptions() async {
    _subscriptions = await SPManager.getSubscriptions();
    if (_subscriptions.isNotEmpty) {
      setState(() {
        selectSite = _subscriptions[0]['name'] ?? ""; // 默认选择第一个站点
      });
    }
    _loadSearchResults(selectSite);
  }

  // 加载搜索历史记录
  Future<void> _loadSearchHistory() async {
    _searchHistory = await SPManager.getSearchHistory() ?? [];
    setState(() {});
  }

  // 保存搜索历史
  Future<void> _saveSearchHistory(String query) async {
    if (query.isEmpty || _searchHistory.contains(query)) return;
    setState(() {
      _searchHistory.add(query);
      if (_searchHistory.length > 20) _searchHistory.removeAt(0); // 限制最多20条
    });
    await SPManager.freshSearchHistory(_searchHistory);
  }

  // 执行搜索
  Future<void> _searchVideos() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearch = true;
      _searchResults.clear();
    });

    await _saveSearchHistory(query);

    try {
      for (var subscription in _subscriptions) {
        String subscriptionName = subscription['name'] ?? '未知站点';
        String subscriptionDomain = subscription['domain'] ?? '';

        Map<String, dynamic> newJsonMap = await _httpService.getBySubscription(
          subscriptionDomain,
          "",
          params: {
            "ac": "detail",
            "wd": query,
          },
        );

        setState(() {
          _searchResults[subscriptionName] =
              RealResponseData.fromJson(newJsonMap, subscriptionDomain);
          _loadSearchResults(selectSite);
        });
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 清空搜索历史记录
  Future<void> _clearSearchHistory() async {
    setState(() {
      _searchHistory.clear();
    });
    SPManager.freshSearchHistory(_searchHistory);
  }

  // 删除单条历史记录
  Future<void> _deleteSearchHistory(int index) async {
    setState(() {
      _searchHistory.removeAt(index);
    });
    SPManager.freshSearchHistory(_searchHistory);
  }

  // 加载特定站点的搜索结果
  Future<void> _loadSearchResults(String siteName) async {
    if (_searchResults.containsKey(siteName)) {
      setState(() {
        selectResponseData = _searchResults[siteName]!;
      });
    } else {
      setState(() {
        selectResponseData = RealResponseData.empty();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            const SizedBox(height: 30.0),
            // 搜索框
            _buildSearchInput(),
            // 搜索历史
            if (_searchHistory.isNotEmpty) _buildSearchHistory(),
            SizedBox(
              height: 10,
            ),

            //搜索结果
            if (_subscriptions.isNotEmpty) _buildSearchResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Column(
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
                onLongPress: () =>
                    _deleteSearchHistory(_searchHistory.indexOf(history)),
                child: SizedBox(
                  height: 30,
                  child: Chip(
                    label: Text(history, style: TextStyle(fontSize: 11.0)),
                    deleteIcon: Icon(Icons.close, size: 14.0),
                    onDeleted: () =>
                        _deleteSearchHistory(_searchHistory.indexOf(history)),
                  ),
                ));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResult() {
    if (_isLoading) {
      return CircularProgressIndicator();
    } else {
      return Expanded(
          child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _subscriptions.length,
              itemBuilder: (context, index) {
                var site = _subscriptions[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectSite = site['name'] ?? "";
                      _loadSearchResults(selectSite);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      site['name'] ?? "",
                      style: TextStyle(
                          fontSize: 13.0,
                          color: (site['name'] == selectSite)
                              ? Colors.red
                              : Colors.black,
                          fontWeight: (site['name'] == selectSite)
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 6,
            child: selectResponseData.videos.isEmpty
                ? Center(
                    child: Text(_hasSearch?"没有找到相关视频":""),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: selectResponseData.videos.length,
                    itemBuilder: (context, index) {
                      var video = selectResponseData.videos[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailScreen(
                                  vodId: video.vodId,
                                  subscription: video.subscriptionDomain,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              SizedBox(
                                height: 80,
                                width: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: LoadingImage(pic: video.vodPic),
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      video.vodName,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2.0),
                                    Row(
                                      children: [
                                        Text(
                                          video.vodRemarks,
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 8.0),
                                        Text(
                                          video.vodPubdate,
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      video.vodArea,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      video.typeName,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ));
    }
  }

  Widget _buildSearchInput() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) => _searchVideos(),
              decoration: const InputDecoration(
                hintText: "输入搜索内容",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
              ),
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
        ),
        SizedBox(width: 8.0),
        GestureDetector(
          onTap: _searchVideos,
          child: Text("搜索"),
        ),
      ],
    );
  }
}
