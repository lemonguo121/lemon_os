class ParesVideo {
  final String vodName;
  final String vodPic;
  final String vodPlayUrl;

  ParesVideo({
    required this.vodName,
    required this.vodPic,
    required this.vodPlayUrl,
  });

  // 从JSON解析
  factory ParesVideo.fromJson(Map<String, dynamic> json,) {
    return ParesVideo(
      vodName: json['data']['title'] ?? "",
      vodPic: json['data']['cover'] ?? '',
      vodPlayUrl: json['data']['play'] ?? '',
    );
  }

  // 将 RealVideo 对象转换为 JSON 字符串
  Map<String, dynamic> toJson() {
    return {
      'vodName': vodName,
      'vodPic': vodPic,
      'vodPlayUrl': vodPlayUrl,
    };
  }

  factory ParesVideo.fromJson2(Map<String, dynamic> json) {
    return ParesVideo(
        vodName: json['vodName'],
        vodPic: json['vodPic'],
        vodPlayUrl: json['vodPlayUrl']);
    }
}
