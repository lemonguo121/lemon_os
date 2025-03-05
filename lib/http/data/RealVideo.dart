class RealVideo {
  final int vodId;
  final String vodName;
  final String vodSub;
  final String vodPic;
  final String vodActor;
  final String vodBlurb;
  final String vodRemarks;
  final String vodPubdate;
  final String vodArea;
  final String vodYear;
  final String typeName;
  final String vodPlayUrl;
  final int typePid;
  final String subscriptionDomain;

  // 构造函数名称应与类名一致
  RealVideo({
    required this.vodId,
    required this.vodName,
    required this.vodSub,
    required this.vodPic,
    required this.vodActor,
    required this.vodBlurb,
    required this.vodRemarks,
    required this.vodPubdate,
    required this.vodArea,
    required this.typeName,
    required this.vodYear,
    required this.vodPlayUrl,
    required this.typePid,
    required this.subscriptionDomain,
  });

  // 从JSON解析
  factory RealVideo.fromJson(Map<String, dynamic> json, subscriptionDomain) {
    return RealVideo(
      vodId: json['vod_id'] ?? 0,
      vodName: json['vod_name'] ?? '',
      vodSub: json['vod_sub'] ?? '',
      vodPic: json['vod_pic'] ?? '',
      vodActor: json['vod_actor'] ?? '',
      vodBlurb: json['vod_blurb'] ?? '',
      vodRemarks: json['vod_remarks'] ?? '',
      vodPubdate: json['vod_pubdate'] ?? '',
      vodArea: json['vod_area'] ?? '',
      typeName: json['type_name'] ?? '',
      vodYear: json['vod_year'] ?? '未知年份',
      vodPlayUrl: json['vod_play_url'] ?? '',
      typePid: json['type_id_1'] ?? '',
      subscriptionDomain: subscriptionDomain,
    );
  }

  // 将 RealVideo 对象转换为 JSON 字符串
  Map<String, dynamic> toJson() {
    return {
      'vodId': vodId,
      'vodName': vodName,
      'vodSub': vodSub,
      'vodPic': vodPic,
      'vodActor': vodActor,
      'vodBlurb': vodBlurb,
      'vodBlurb': vodBlurb,
      'vodRemarks': vodRemarks,
      'vodPubdate': vodPubdate,
      'vodArea': vodArea,
      'vodYear': vodYear,
      'typeName': typeName,
      'vodPlayUrl': vodPlayUrl,
      'typePid': typePid,
      'subscriptionDomain': subscriptionDomain,
    };
  }

  factory RealVideo.fromJson2(Map<String, dynamic> json) {
    return RealVideo(
      vodId: json['vodId'],
      vodName: json['vodName'],
      vodSub: json['vodSub'],
      vodPic: json['vodPic'],
      vodActor: json['vodActor'],
      vodBlurb: json['vodBlurb'],
      vodRemarks: json['vodRemarks'],
      vodPubdate: json['vodPubdate'],
      vodArea: json['vodArea'],
      vodYear: json['vodYear'],
      typeName: json['typeName'],
      vodPlayUrl: json['vodPlayUrl'],
      typePid: json['typePid'],
      subscriptionDomain: json['subscriptionDomain'],
    );
  }
}

class RealResponseData {
  final int code;
  final String msg;
  List<RealVideo> videos;

  RealResponseData({
    required this.code,
    required this.msg,
    required this.videos,
  });

  static RealResponseData empty() {
    return RealResponseData(
      code: 0,
      msg: '',
      videos: [], // 空的搜索结果列表
    );
  }

  // 从JSON解析
  factory RealResponseData.fromJson(
      Map<String, dynamic> json, subscriptionDomain) {
    var list = json['list'] as List;
    List<RealVideo> videosList =
        list.map((i) => RealVideo.fromJson(i, subscriptionDomain)).toList();

    return RealResponseData(
      code: json['code'],
      msg: json['msg'],
      videos: videosList,
    );
  }
}
