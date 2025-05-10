class DownloadItem {
  final String url;
  final int progress;
  final DownloadStatus status;
  final String? localPath;

  DownloadItem({
    required this.url,
    required this.progress,
    required this.status,
    required this.localPath,
  });

  // 用于从 JSON 数据恢复 DownloadItem
  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      url: json['url'],
      progress: json['progress'],
      status: DownloadStatus.values[json['status']],
      localPath:json['localPath'],
    );
  }

  // 用于将 DownloadItem 转换为 JSON 数据
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'progress': progress,
      'status': status.index,
      'localPath': localPath,
    };
  }

  // 用于更新 DownloadItem 的进度或状态
  DownloadItem copyWith({
    String? url,
    int? progress,
    DownloadStatus? status,
    String? localPath,
  }) {
    return DownloadItem(
      url: url ?? this.url,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      localPath: localPath ?? this.localPath,
    );
  }
}

enum DownloadStatus { downloading, paused, completed, failed }