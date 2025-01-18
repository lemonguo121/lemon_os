import 'dart:convert';

import 'AlClass.dart';

// 视频数据模型
class Video {
  final int vodId;
  final String vodName;
  final int typeId;
  final String typeName;
  final String vodEn;
  final String vodTime;
  final String vodRemarks;
  final String vodPlayFrom;

  Video({
    required this.vodId,
    required this.vodName,
    required this.typeId,
    required this.typeName,
    required this.vodEn,
    required this.vodTime,
    required this.vodRemarks,
    required this.vodPlayFrom,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      vodId: json['vod_id'],
      vodName: json['vod_name'],
      typeId: json['type_id'],
      typeName: json['type_name'],
      vodEn: json['vod_en'],
      vodTime: json['vod_time'],
      vodRemarks: json['vod_remarks'],
      vodPlayFrom: json['vod_play_from'],
    );
  }
}

class ResponseData {
  final int code;
  final String msg;
  final int page;
  final int pageCount;
  final String limit;
  final int total;
  final List<Video> videos;
  final List<AlClass> alClass;

  ResponseData({
    required this.code,
    required this.msg,
    required this.page,
    required this.pageCount,
    required this.limit,
    required this.total,
    required this.videos,
    required this.alClass,
  });

  factory ResponseData.fromJson(Map<String, dynamic> json) {
    var videoList = json['list'] as List;
    var classList = json['class'] as List;
    List<Video> videos = videoList.map((e) => Video.fromJson(e)).toList();
    List<AlClass> allClass = classList.map((e) => AlClass.fromJson(e)).toList();

    return ResponseData(
      code: json['code'],
      msg: json['msg'],
      page: json['page'],
      pageCount: json['pagecount'],
      limit: json['limit'],
      total: json['total'],
      videos: videos,
      alClass: allClass,
    );
  }
}
