import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/util/CommonUtil.dart';
import 'package:lemon_tv/util/SubscriptionsUtil.dart';
import 'package:xml/xml.dart';

import '../detail/DetailScreen.dart';
import '../http/HttpService.dart';
import '../http/data/RealVideo.dart';
import '../http/data/storehouse_bean_entity.dart';
import '../routes/routes.dart';
import '../util/SPManager.dart';
import '../util/ThemeController.dart';
import 'SearchHistoryList.dart';
import 'SearchResultList.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:just_audio/just_audio.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  final HttpService _httpService = HttpService();
  List<String> _searchHistory = [];
  Map<String, RealResponseData> _searchResults = {}; // 以站点名存储不同站点的搜索结果
  List<StorehouseBeanSites> selectStorehouse = [];
  late RealResponseData selectResponseData;
  String selectSite = ""; // 当前选择的站点名
  bool _hasSearch = false;
  List<String> hasResultSite = [];
  List<String> suggestions = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final ThemeController themeController = Get.find();
  String query = '';

  //语音搜索
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    var arguments = Get.arguments;
    query = arguments['query'];
    _initializeData();
  }

  void _initializeData() async {
    await Future.wait([_loadSearchHistory(), _loadSubscriptions()]);
    _startQucikSearch();
  }

  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.setAudioSource(AudioSource.asset(assetPath));
      await _audioPlayer.play();
    } catch (e) {
      print("播放提示音失败: $e");
    }
  }

  // 加载已订阅站点
  Future<void> _loadSubscriptions() async {
    selectStorehouse = SubscriptionsUtil().selectStorehouse;
    // _subscriptions = await SPManager.getStorehouse();
    if (selectStorehouse.isNotEmpty) {
      setState(() {
        selectSite = selectStorehouse.first.name; // 默认选择第一个站点
      });
    }
    _loadSearchResults(selectSite);
  }

  // 加载搜索历史记录
  Future<void> _loadSearchHistory() async {
    _searchHistory = SPManager.getSearchHistory();
    setState(() {});
  }

  // 保存搜索历史
  _saveSearchHistory(String query) {
    if (query.isEmpty || _searchHistory.contains(query)) return;
    setState(() {
      _searchHistory.add(query);
      if (_searchHistory.length > 20) _searchHistory.removeAt(0); // 限制最多20条
    });
    SPManager.freshSearchHistory(_searchHistory);
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
      for (var site in selectStorehouse) {
        String subscriptionName = site.name ?? '未知站点';
        String subscriptionDomain = site.api ?? '';
        int paresType = site.type ?? 1;
        var response;
        if (paresType == 1) {
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
          response = RealResponseData.fromJson(newJsonMap, site);
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
          response = RealResponseData.fromXml(newJsonMap, site);
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
    _hideSuggestions();
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
    _hideSuggestions();
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
            if (selectStorehouse.isNotEmpty)
              SearchResultList(
                  isLoading: _isLoading,
                  hasResultSite: hasResultSite,
                  selectSite: selectSite,
                  loadSearchResults: _loadSearchResults,
                  clickVideoItem: _clickVideoItem,
                  selectResponseData: selectResponseData,
                  hasSearch: _hasSearch),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Obx(() {
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _performSearch(value);
                  },
                  onSubmitted: (value) => _searchVideos(),
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            themeController.currentAppTheme.selectedTextColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    hintText: "输入搜索内容",
                    hintStyle: TextStyle(
                        color: themeController.currentAppTheme.contentColor),
                    prefixIcon: Icon(
                      Icons.search,
                      color: themeController.currentAppTheme.contentColor,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            themeController.currentAppTheme.selectedTextColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
                  ),
                  style: TextStyle(
                      fontSize: 16.0,
                      color: themeController.currentAppTheme.titleColr),
                ),
              ),
            ),
            SizedBox(width: 10.0),
            SizedBox(
                height: 30,
                width: 30,
                child: Obx(
                  () => GestureDetector(
                    child: Icon(_isListening ? Icons.mic : Icons.mic_none,
                        color: themeController.currentAppTheme.contentColor),
                    onLongPressStart: (_) => _startListening(),
                    onLongPressEnd: (_) => _stopListening(),
                  ),
                )),
            SizedBox(width: 8.0),
          ],
        );
      }),
    );
  }

  void _startListening() async {
    _playSound('assets/sounds/begin_record.mp3'); // 播放开始提示音
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: 'zh_CN', // 中文识别
        onResult: (result) {
          setState(
            () {
              _searchController.text = result.recognizedWords;
            },
          );
        },
      );
    }
  }

  void _stopListening() {
    _playSound('assets/sounds/begin_record.mp3'); // 播放开始提示音
    _speech.stop();
    FocusScope.of(context).unfocus();
    setState(() => _isListening = false);
    _searchVideos(); // 语音停止后执行搜索
  }

  void _startQucikSearch() {
    if (query.isNotEmpty) {
      _searchController.text = query;
      _searchVideos();
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isNotEmpty) {
      suggestions = await _httpService.getSuggest(query);
      print("suggestions = ${suggestions.length}");
      if (suggestions.isNotEmpty) {
        _showSuggestions();
      } else {
        _hideSuggestions();
      }
    } else {
      _hideSuggestions();
    }
  }

  void _showSuggestions() {
    _hideSuggestions(); // 先清除旧的 overlay

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: CommonUtil.getScreenWidth(context) * 0.8,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0.0, 45.0), // 控制弹出框的偏移量
          child: GestureDetector(
            // 点击任何地方都会关闭 overlay
            onTap: () {
              _hideSuggestions(); // 关闭 overlay
            },
            child: Material(
              elevation: 2.0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.0),
                constraints: BoxConstraints(
                  maxHeight: 200,
                ), // 限制最大高度
                color: Colors.white,
                child: SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.start, // 让内容靠左排列
                    spacing: 2.0, // 每个条目之间的水平间距
                    runSpacing: 0.1, // 每行之间的垂直间距
                    children: suggestions.map((suggestion) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchController.text = suggestion;
                            _searchVideos();
                            _hideSuggestions();
                          });
                        },
                        child: Chip(
                          padding: EdgeInsets.zero,
                          label: Text(
                            suggestion,
                            style: TextStyle(fontSize: 12.0),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _clickVideoItem(RealVideo video) {
    _hideSuggestions();
    Routes.goDetailPage('${video.vodId}', video.site);
  }
}
