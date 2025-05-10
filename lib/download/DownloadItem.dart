import 'package:dio/dio.dart';

enum DownloadStatus { downloading, paused, completed, failed }

class DownloadItem {
  final String url;
  int progress;
  DownloadStatus status;
  String? localPath;
  CancelToken cancelToken;
  int currentIndex;
  List<String> localSegments;

  DownloadItem({
    required this.url,
    required this.progress,
    required this.status,
    required this.localPath,
    required this.cancelToken,
    required this.currentIndex,
    required this.localSegments,
  });

  /// 从 JSON 恢复 DownloadItem（cancelToken 始终新建）
  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      url: json['url'],
      progress: json['progress'],
      status: DownloadStatus.values[json['status']],
      localPath: json['localPath'],
      cancelToken: CancelToken(),
      // 始终新建一个新的 cancelToken
      currentIndex: json['currentIndex'] ?? 0,
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
      'progress': progress,
      'status': status.index,
      'localPath': localPath,
      'currentIndex': currentIndex,
      'localSegments': localSegments,
    };
  }

  /// 更新 DownloadItem 实例（不可变）
  DownloadItem copyWith({
    String? url,
    int? progress,
    DownloadStatus? status,
    String? localPath,
    CancelToken? cancelToken,
    int? currentIndex,
    List<String>? localSegments,
  }) {
    return DownloadItem(
      url: url ?? this.url,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      localPath: localPath ?? this.localPath,
      cancelToken: cancelToken ?? this.cancelToken,
      currentIndex: currentIndex ?? this.currentIndex,
      localSegments: localSegments ?? List.from(this.localSegments),
    );
  }
}
