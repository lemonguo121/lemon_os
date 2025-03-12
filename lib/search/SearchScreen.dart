import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../http/HttpService.dart';
import '../http/data/RealVideo.dart';
import '../util/SPManager.dart';
import 'SearchHistoryList.dart';
import 'SearchResultList.dart';

class SearchScreen extends StatefulWidget {
  final String query;

  const SearchScreen({super.key, required this.query});

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
  List<String> hasResultSite = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    await Future.wait([_loadSearchHistory(), _loadSubscriptions()]);
    _startQucikSearch();
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
      hasResultSite.clear();
    });

    await _saveSearchHistory(query);

    try {
      var isResearch = false;
      for (var subscription in _subscriptions) {
        String subscriptionName = subscription['name'] ?? '未知站点';
        String subscriptionDomain = subscription['domain'] ?? '';
        String paresType = subscription['paresType'] ?? "1";
        var response;
        if (paresType == "1") {
          Map<String, dynamic> newJsonMap =
              await _httpService.getBySubscription(
            subscriptionDomain,
            paresType,
            "",
            params: {
              "ac": "detail",
              "wd": query,
            },
          );
          response = RealResponseData.fromJson(newJsonMap, subscription);
        } else {
          XmlDocument newJsonMap = await _httpService.getBySubscription(
            subscriptionDomain,
            paresType,
            "",
            params: {
              "ac": "videolist",
              "wd": query,
            },
          );
          response = RealResponseData.fromXml(newJsonMap, subscription);
        }

        setState(() {
          _searchResults[subscriptionName] = response;
          if (response != null && response.videos.isNotEmpty) {
            hasResultSite.add(subscriptionName);
            if (!isResearch) {
              selectSite = subscriptionName;
              isResearch = true;
              _loadSearchResults(selectSite);
            }

            _isLoading = false;
          }
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
        selectSite = siteName;
        selectResponseData = _searchResults[siteName]!;
      });
    } else {
      setState(() {
        selectResponseData = RealResponseData.empty();
      });
    }
  }

  void _changeEditControll(String historyContent) {
    _searchController.text = historyContent;
    _searchVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            const SizedBox(height: 40.0),
            // 搜索框
            _buildSearchInput(),
            // 搜索历史
            if (_searchHistory.isNotEmpty)
              SearchHistoryList(
                  searchHistory: _searchHistory,
                  changeEditingController: _changeEditControll,
                  deleteSearchHistory: _deleteSearchHistory,
                  clearSearchHistory: _clearSearchHistory),
            SizedBox(
              height: 10,
            ),

            //搜索结果
            if (_subscriptions.isNotEmpty)
              SearchResultList(
                  isLoading: _isLoading,
                  hasResultSite: hasResultSite,
                  selectSite: selectSite,
                  loadSearchResults: _loadSearchResults,
                  selectResponseData: selectResponseData,
                  hasSearch: _hasSearch),
          ],
        ),
      ),
    );
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

  void _startQucikSearch() {
    if (widget.query.isNotEmpty) {
      _searchController.text = widget.query;
      _searchVideos();
    }
  }
}
