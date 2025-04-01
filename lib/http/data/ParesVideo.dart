class ParesVideo {
  final String vodId;
  final String vodName;
  final String vodPic;
  final String vodPlayUrl;
  final String vodFrom;
  final String vodRemarks;

  ParesVideo({
    required this.vodId,
    required this.vodName,
    required this.vodPic,
    required this.vodPlayUrl,
    required this.vodFrom,
    required this.vodRemarks,
  });

  // 从JSON解析
  factory ParesVideo.fromJson(
      Map<String, dynamic> json, String site, String source) {
    return ParesVideo(
      vodId: json['data']['id'] ?? "",
      vodName: json['data']['title'] ?? "",
      vodPic: json['data']['cover'] ?? '',
      vodPlayUrl: json['data']['play'] ?? '',
      vodFrom: site,
      vodRemarks: source,
    );
  }

  // 将 RealVideo 对象转换为 JSON 字符串
  Map<String, dynamic> toJson() {
    return {
      'vodId': vodId,
      'vodName': vodName,
      'vodPic': vodPic,
      'vodPlayUrl': vodPlayUrl,
      'vodFrom': vodFrom,
      'vodRemarks': vodRemarks
    };
  }

  factory ParesVideo.fromJson2(Map<String, dynamic> json) {
    return ParesVideo(
        vodId: json['vodId'],
        vodName: json['vodName'],
        vodPic: json['vodPic'],
        vodPlayUrl: json['vodPlayUrl'],
        vodFrom: json['vodFrom'],
        vodRemarks: json['vodRemarks']??"");
  }
}
