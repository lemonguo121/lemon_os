class DownloadItem {
  final String url;
  final int progress; // 0 - 100
  final DownloadStatus status;

  DownloadItem({
    required this.url,
    this.progress = 0,
    this.status = DownloadStatus.downloading,
  });

  DownloadItem copyWith({
    String? url,
    int? progress,
    DownloadStatus? status,
  }) {
    return DownloadItem(
      url: url ?? this.url,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }
}

enum DownloadStatus {
  downloading,
  paused,
  completed,
  failed,
}