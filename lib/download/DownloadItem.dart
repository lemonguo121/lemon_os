import 'package:dio/dio.dart';

import '../http/data/storehouse_bean_entity.dart';

enum DownloadStatus { downloading, paused, conversioning,completed, failed }

class DownloadItem {
  final String url;
  final String vodId;
  final String vodPic;
  final String playTitle;
  final int playIndex;
  final String vodName;
  final StorehouseBeanSites site;
  int progress;
  DownloadStatus status;
  String? localPath;
  CancelToken cancelToken;
  int currentIndex;
  double downloadedBytes;
  List<String> localSegments;

  DownloadItem({
    required this.url,
    required this.vodId,
    required this.vodPic,
    required this.playTitle,
    required this.playIndex,
    required this.vodName,
    required this.site,
    required this.progress,
    required this.status,
    required this.localPath,
    required this.cancelToken,
    required this.currentIndex,
    required this.downloadedBytes,
    required this.localSegments,
  });

  /// 从 JSON 恢复 DownloadItem（cancelToken 始终新建）
  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      url: json['url'],
      vodId: json['vodId'],
      vodPic: json['vodPic'],
      playTitle: json['playTitle'],
      playIndex: json['playIndex'],
      site: StorehouseBeanSites.fromJson(json['site']),
      vodName: json['vodName'],
      progress: json['progress'],
      status: DownloadStatus.values[json['status']],
      localPath: json['localPath'],
      cancelToken: CancelToken(),
      // 始终新建一个新的 cancelToken
      currentIndex: json['currentIndex'] ?? 0,
      downloadedBytes: json['downloadedBytes'],
      localSegments: (json['localSegments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// 转换为 JSON（cancelToken 不可序列化）
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'vodId': vodId,
      'vodPic': vodPic,
      'playIndex': playIndex,
      'playTitle': playTitle,
      'vodName': vodName,
      'site': site,
      'progress': progress,
      'status': status.index,
      'localPath': localPath,
      'currentIndex': currentIndex,
      'downloadedBytes': downloadedBytes,
      'localSegments': localSegments,
    };
  }

  /// 更新 DownloadItem 实例（不可变）
  DownloadItem copyWith({
    String? url,
    String? vodId,
    String? vodPic,
    String? playTitle,
    int? playIndex,
    String? vodName,
    StorehouseBeanSites? site,
    int? progress,
    DownloadStatus? status,
    String? localPath,
    CancelToken? cancelToken,
    int? currentIndex,
    double? downloadedBytes,
    List<String>? localSegments,
  }) {
    return DownloadItem(
      url: url ?? this.url,
      vodId: vodId ?? this.vodId,
      vodPic: vodPic ?? this.vodPic,
      playTitle: playTitle ?? this.playTitle,
      playIndex: playIndex ?? this.playIndex,
      vodName: vodName ?? this.vodName,
      site: site ?? this.site,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      localPath: localPath ?? this.localPath,
      cancelToken: cancelToken ?? this.cancelToken,
      currentIndex: currentIndex ?? this.currentIndex,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      localSegments: localSegments ?? List.from(this.localSegments),
    );
  }
}
