class VideoPlayData {
  final List<List<Map<String, String>>> playList; // 每个来源对应一个播放列表
  final List<String> fromList; // 来源列表
  final List<Map<String, String>> currentPlayGroup; // 当前选择的播放组

  VideoPlayData({
    required this.playList,
    required this.fromList,
    required this.currentPlayGroup,
  });
}