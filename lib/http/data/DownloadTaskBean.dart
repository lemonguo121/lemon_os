class DownloadTaskBean {
  int id;
  String name;
  int progress;
  String url;
  String status;
  String savedPath;

  DownloadTaskBean({
    required this.id,
    required this.name,
    required this.progress,
    required this.url,
    required this.status,
    required this.savedPath,
  });

  set setStatus(String newStatus) {
    status = newStatus;
  }

  set setProgress(int newProgress) {
    progress = newProgress;
  }

  // 转换为字符串，方便存储
  @override
  String toString() {
    return '$id,$name,$progress,$status,$savedPath';
  }

  // 从字符串解析任务
  factory DownloadTaskBean.fromString(String taskString) {
    final parts = taskString.split(',');
    return DownloadTaskBean(
      id: int.parse(parts[0]),
      name: parts[1],
      progress: int.parse(parts[2]),
      url: parts[3],
      status: parts[4],
      savedPath: parts[5],
    );
  }
}