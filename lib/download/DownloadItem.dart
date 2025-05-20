import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../http/data/storehouse_bean_entity.dart';

enum DownloadStatus {
  downloading,
  paused,
  conversioning,
  completed,
  failed,
  converfaild,
  pending
}

class DownloadItem {
  final String url;
  final String vodId;
  final String vodPic;
  final String playTitle;
  final int playIndex;//这是剧集中的索引
  final String vodName;
  final StorehouseBeanSites site;
  final RxInt progress;
  final Rx<DownloadStatus> status;
  String? localPath;
  String? folder;
  CancelToken cancelToken;
  int currentIndex;//这是下载的m3u8中的ts切片索引
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
    required int progress,
    required DownloadStatus status,
    this.localPath,
    this.folder,
    CancelToken? cancelToken,
    this.currentIndex = 0,
    this.downloadedBytes = 0.0,
    List<String>? localSegments,
  })  : progress = progress.obs,
        status = status.obs,
        cancelToken = cancelToken ?? CancelToken(),
        localSegments = localSegments ?? [];

  /// 从 JSON 恢复 DownloadItem（Rx 包装）
  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      url: json['url'],
      vodId: json['vodId'],
      vodPic: json['vodPic'],
      playTitle: json['playTitle'],
      playIndex: json['playIndex'],
      vodName: json['vodName'],
      site: StorehouseBeanSites.fromJson(json['site']),
      progress: json['progress'] ?? 0,
      status: DownloadStatus.values[json['status'] ?? 0],
      localPath: json['localPath'],
      folder: json['folder'],
      currentIndex: json['currentIndex'] ?? 0,
      downloadedBytes: (json['downloadedBytes'] ?? 0).toDouble(),
      localSegments: (json['localSegments'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }

  /// 转换为 JSON（Rx.value 序列化）
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'vodId': vodId,
      'vodPic': vodPic,
      'playTitle': playTitle,
      'playIndex': playIndex,
      'vodName': vodName,
      'site': site.toJson(),
      'progress': progress.value,
      'status': status.value.index,
      'localPath': localPath,
      'folder': folder,
      'currentIndex': currentIndex,
      'downloadedBytes': downloadedBytes,
      'localSegments': localSegments,
    };
  }

  /// 创建一个新对象副本（Rx 类型保留 .value）
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
    String? folder,
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
      progress: progress ?? this.progress.value,
      status: status ?? this.status.value,
      localPath: localPath ?? this.localPath,
      folder: folder ?? this.folder,
      cancelToken: cancelToken ?? this.cancelToken,
      currentIndex: currentIndex ?? this.currentIndex,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      localSegments: localSegments ?? List.from(this.localSegments),
    );
  }

  /// 是否处于下载中
  bool get isDownloading => status.value == DownloadStatus.downloading;

  /// 是否已完成
  bool get isCompleted => status.value == DownloadStatus.completed;
}