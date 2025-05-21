import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lemon_tv/http/data/RealVideo.dart';
import 'package:lemon_tv/player/controller/VideoPlayerGetController.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../util/SPManager.dart';
import 'DownloadItem.dart';

class DownloadController extends GetxController {
  var downloads = <DownloadItem>[].obs;
  var maxConcurrentDownloads = SPManager.getMaxConcurrentDownloads().obs;
  final RxList<DownloadItem> activeDownloads = <DownloadItem>[].obs;
  final Queue<DownloadItem> pendingQueue = Queue<DownloadItem>();
  VideoPlayerGetController playerGetController = Get.find();
  final RxList<ConnectivityResult> connectionStatus =
      <ConnectivityResult>[].obs;
  final Connectivity _connectivity = Connectivity();
  void startListening() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    connectionStatus.value = results;
    final hasWifi = results.contains(ConnectivityResult.wifi);
    final hasMobile = results.contains(ConnectivityResult.mobile);
    final hasNone =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);

    if (hasWifi) {
      resumeAllTask();
    } else if (hasMobile) {
      pauseAllTask();
      await _showNonWifiDialogWithGetX();
    } else if (hasNone) {
      pauseAllTask();
    }
  }

  Future<void> _showNonWifiDialogWithGetX() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('提示'),
        content: Text('当前为移动网络，是否继续下载？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('继续'),
          ),
        ],
      ),
      barrierDismissible: false, // 不让用户点击外部关闭对话框（可选）
    );

    if (result == true) {
      resumeAllTask();
    } else {
      pauseAllTask();
    }
  }

  void pauseAllTask() {
    for (var value in downloads) {
      if (DownloadStatus.downloading == value.status.value) {
        pauseDownload(value.url, false);
      }
    }
  }

  void resumeAllTask() {
    for (var value in downloads) {
      if (DownloadStatus.completed != value.status.value) {
        resumeDownload(value.url);
      }
    }
  }

  RxList<DownloadItem> getEpisodesByVodName(String vodName) {
    return downloads.where((item) => item.vodName == vodName).toList().obs;
  }

  Map<String, List<DownloadItem>> get groupedByVodName {
    final map = <String, List<DownloadItem>>{};
    for (var item in downloads) {
      map.putIfAbsent(item.vodName, () => []).add(item);
    }
    return map;
  }

  final Dio dio = Dio();

  bool startDownload(
      String url, String playTitle, int playIndex, RealVideo video) {
    if (downloads.any((d) => d.url == url)) {
      print("任务已存在: $url");
      return false;
    }

    final cancelToken = CancelToken();
    final newItem = DownloadItem(
      url: url,
      vodId: '${video.vodId}',
      vodPic: video.vodPic,
      playTitle: playTitle,
      playIndex: playIndex,
      vodName: video.vodName,
      site: video.site,
      progress: 0,
      status: DownloadStatus.downloading,
      localPath: '',
      cancelToken: cancelToken,
      currentIndex: 0,
      downloadedBytes: 0,
      localSegments: [],
    );
    downloads.add(newItem);
    downloads.refresh();
    SPManager.saveDownloads(downloads);

    _tryStartDownload(newItem);
    return true;
  }

  Future<void> _tryStartDownload(DownloadItem item) async {
    if (activeDownloads.length < maxConcurrentDownloads.value) {
      item.status.value = DownloadStatus.downloading;
      activeDownloads.add(item);
      downloads.refresh();
      if (item.url.endsWith('.m3u8')) {
        final resolvedUrl = await resolveFinalM3U8Url(item.url);
        item.url = resolvedUrl;
        _downloadM3u8(item.url, false).then((_) => _onDownloadComplete(item));
      } else {
        _downloadVideo(item.url).then((_) => _onDownloadComplete(item));
      }
      connectionStatus.value = await _connectivity.checkConnectivity();
      var hasMobile = connectionStatus.contains(ConnectivityResult.mobile);
      if (hasMobile) {
        pauseAllTask();
        await _showNonWifiDialogWithGetX();
      }
    } else {
      print("任务已加入等待队列: ${item.url}");
      item.status.value = DownloadStatus.pending;
      pendingQueue.add(item);
    }
  }

  void _onDownloadComplete(DownloadItem item) {
    activeDownloads.removeWhere((d) => d.url == item.url);
    // 检查是否有排队任务
    if (pendingQueue.isNotEmpty) {
      final nextItem = pendingQueue.removeFirst();
      _tryStartDownload(nextItem);
    }
  }

  void pauseDownload(String url, bool isNeednext) {
    //isNeednext  是否需要跳到下一个任务，手动暂停单个时，我们跳下一个，暂停所有就不跳了不然控制不了
    final item = downloads.firstWhereOrNull((d) => d.url == url);
    if (item != null && item.status.value == DownloadStatus.downloading) {
      item.cancelToken.cancel("手动暂停");
      updateStatus(url, DownloadStatus.paused);
      activeDownloads.removeWhere((d) => d.url == url);
      if (isNeednext) {
        _startNextIfPossible();
      }
    }
  }

  void _startNextIfPossible() {
    if (pendingQueue.isNotEmpty &&
        activeDownloads.length < maxConcurrentDownloads.value) {
      final nextItem = pendingQueue.removeFirst();
      _tryStartDownload(nextItem);
    }
  }

  void resumeDownload(String url) {
    final item = downloads.firstWhereOrNull((d) => d.url == url);
    if (item != null &&
        (item.status.value == DownloadStatus.paused ||
            item.status.value == DownloadStatus.failed)) {
      final newCancelToken = CancelToken();
      item.cancelToken = newCancelToken;
      _tryStartDownload(item);
    }
  }

  void updateStatus(String url, DownloadStatus status) {
    final index = downloads.indexWhere((d) => d.url == url);
    if (index != -1) {
      downloads[index].status.value = status;
      downloads.refresh();
      SPManager.saveDownloads(downloads);
      WakelockPlus.toggle(
          enable: !checkTaskAllDone() || playerGetController.initialize.value);
    }
  }

  void updateProgress(String url, int progress, double downloadedBytes) {
    final index = downloads.indexWhere((d) => d.url == url);
    if (index != -1) {
      downloads[index].progress.value = progress;
      downloads[index].downloadedBytes = downloadedBytes;
      downloads.refresh();
      SPManager.saveDownloads(downloads);
    }
  }

  void updateLocalPath(String url, String path) {
    final index = downloads.indexWhere((d) => d.url == url);
    if (index != -1) {
      downloads[index].localPath = path;
      downloads.refresh();
      SPManager.saveDownloads(downloads);
    }
  }

  void updatefolder(String url, String folder) {
    final index = downloads.indexWhere((d) => d.url == url);
    if (index != -1) {
      downloads[index].folder = folder;
      downloads.refresh();
      SPManager.saveDownloads(downloads);
    }
  }

  Future<String> getDownloadDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> _downloadVideo(String url) async {
    final item = downloads.firstWhereOrNull((d) => d.url == url);
    if (item == null) return;

    final dir = await getDownloadDirectory();
    final filename = Uri.parse(url).pathSegments.last;

    final folder = p.join(dir, item.vodName, item.playTitle);
    await Directory(folder).create(recursive: true);
    final savePath = p.join(folder, filename);
    final file = File(savePath);

    int downloadedLength = 0;
    if (await file.exists()) {
      downloadedLength = await file.length();
    } else {
      await file.create(recursive: true);
    }

    try {
      final response = await dio.download(
        url,
        savePath,
        options: Options(
          headers: {
            'Range': 'bytes=$downloadedLength-',
          },
          responseType: ResponseType.stream,
        ),
        cancelToken: item.cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            int fullLength = downloadedLength + total;
            final progress =
                (((downloadedLength + received) / fullLength) * 100).toInt();

            updateProgress(url, progress, fullLength.toDouble());
          }
        },
        deleteOnError: false,
        lengthHeader: Headers.contentLengthHeader,
      );

      updateLocalPath(url, savePath);
      updateStatus(url, DownloadStatus.completed);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        print("下载取消: $url");
      }
    } catch (e) {
      print("下载失败: $e");
      updateStatus(url, DownloadStatus.paused);
    }
  }

  Future<void> _downloadM3u8(String url, bool isResume) async {
    final item = downloads.firstWhereOrNull((d) => d.url == url);
    if (item == null) return;

    // 断点续传时，回退一个切片索引，保证最后一个切片重新下载
    if (isResume && item.currentIndex > 0) {
      final currentSegmentPath = item.localSegments.length > item.currentIndex
          ? item.localSegments[item.currentIndex]
          : null;
      // 删除当前切片文件，准备重新下载
      if (currentSegmentPath != null && File(currentSegmentPath).existsSync()) {
        File(currentSegmentPath).deleteSync();
      }
    }

    var downloadedBytes = item.downloadedBytes;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        updateStatus(url, DownloadStatus.paused);
        return;
      }

      final lines = response.body.split('\n');
      final segmentUrls = lines
          .map((line) => line.trim()) // 去除空白字符，包括 \r、空格等
          .where((line) => !line.startsWith("#") && line.isNotEmpty)
          .toList();

      final dir = await getDownloadDirectory();
      final folder = p.join(dir, item.vodName, item.playTitle);
      await Directory(folder).create(recursive: true);
      updatefolder(url, folder);

      List<String> localSegmentPaths = List<String>.from(item.localSegments);

      for (int i = item.currentIndex; i < segmentUrls.length; i++) {
        if (item.status.value == DownloadStatus.paused ||
            item.cancelToken.isCancelled) {
          print("暂停中断: $url");
          return;
        }

        final segmentUrl = Uri.parse(segmentUrls[i]).isAbsolute
            ? segmentUrls[i]
            : Uri.parse(url).resolve(segmentUrls[i]).toString();
        final savePath = p.join(folder, 'segment_$i.ts');

        try {
          final res = await dio.get<List<int>>(
            segmentUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          await File(savePath).writeAsBytes(res.data!);

          // 记录本地路径
          if (item.localSegments.length <= i) {
            item.localSegments.add(savePath);
          } else {
            // 恢复下载时覆盖旧文件路径
            item.localSegments[i] = savePath;
          }
          localSegmentPaths.add(savePath);

          item.currentIndex = i + 1;
          downloadedBytes += res.data!.length;
          final percent = ((i + 1) / segmentUrls.length * 100).toInt();
          updateProgress(url, percent, downloadedBytes);
        } catch (e) {
          print("下载切片失败: $segmentUrl - $e");
          updateStatus(url, DownloadStatus.failed);
          _startNextIfPossible();
          return;
        }
      }

      // 生成 .m3u8 文件并保存
      final m3u8FilePath = p.join(folder, 'local.m3u8');
      final originalM3u8Path = p.join(folder, 'original.m3u8');
      await File(originalM3u8Path).writeAsString(response.body);
      await convertM3U8(originalM3u8Path, localSegmentPaths, m3u8FilePath);

      // 保存 m3u8 文件路径以便播放器使用
      final m3u8Uri = 'file://$m3u8FilePath';
      updateLocalPath(item.url, m3u8Uri);

      updateStatus(url, DownloadStatus.completed);
    } catch (e) {
      print("解析 m3u8 失败: $e");
      updateStatus(url, DownloadStatus.failed);
    }
  }

  /// 解析并返回真正包含 ts 视频片段的 m3u8 下载地址
  Future<String> resolveFinalM3U8Url(String originUrl) async {
    final uri = Uri.parse(originUrl);
    final baseUri = uri.resolve('.'); // 获取基础目录

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('无法访问 M3U8 文件: ${res.statusCode}');
    }

    final content = utf8.decode(res.bodyBytes);

    // 如果是主索引（多清晰度）
    if (content.contains('#EXT-X-STREAM-INF')) {
      final lines = content.split('\n');
      for (int i = 0; i < lines.length - 1; i++) {
        if (lines[i].startsWith('#EXT-X-STREAM-INF')) {
          final nextLine = lines[i + 1].trim();
          final nextUrl = baseUri.resolve(nextLine).toString();
          print('检测到主索引，使用第一个子 m3u8: $nextUrl');
          return await resolveFinalM3U8Url(nextUrl); // 递归解析
        }
      }
      throw Exception('主索引中未找到有效的子清晰度地址');
    }

    // 否则，当前已是真实的 ts 列表 m3u8，返回当前地址
    print('已解析为最终下载地址: $originUrl');
    return originUrl;
  }

  Future<void> convertM3U8(
    String originalM3U8Path,
    List<String> localTsFiles,
    String outputM3U8Path,
  ) async {
    final originalLines = await File(originalM3U8Path).readAsLines();
    final buffer = StringBuffer();

    int tsIndex = 0;

    for (final line in originalLines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        buffer.writeln(); // 保留空行
      } else if (trimmed.startsWith('#')) {
        buffer.writeln(trimmed); // 标签原样保留
      } else {
        // 非标签行认为是 ts URL，替换成本地 ts 文件名
        if (tsIndex < localTsFiles.length) {
          final localFileName = p.basename(localTsFiles[tsIndex]);
          buffer.writeln(localFileName);
          tsIndex++;
        } else {
          // 万一 localTsFiles 不够，也写一个注释避免出错
          buffer.writeln('# Missing segment for: $trimmed');
        }
      }
    }

    await File(outputM3U8Path).writeAsString(buffer.toString());
  }

  // Future<void> mergeSegments(DownloadItem item) async {
  //   updateStatus(item.url, DownloadStatus.conversioning);
  //   String folder = item.folder ?? '';
  //   final concatList = File(p.join(folder, 'input.txt'));
  //   await concatList.writeAsString(
  //     item.localSegments.map((p) => "file '$p'").join('\n'),
  //   );
  //
  //   final outputPath = p.join(folder, '${item.vodName}_${item.playTitle}.mp4');
  //
  //   final session = await FFmpegKit.execute(
  //       '-f concat -safe 0 -i ${concatList.path} -c copy $outputPath'
  //   );
  //
  //   final returnCode = await session.getReturnCode();
  //   final logs = await session.getAllLogs();
  //   for (final log in logs) {
  //     print("FFmpeg Log: ${log.getMessage()}");
  //   }
  //
  //   if (ReturnCode.isSuccess(returnCode)) {
  //     updateLocalPath(item.url, outputPath);
  //     updateStatus(item.url, DownloadStatus.completed);
  //
  //     for (final f in item.localSegments) {
  //       try {
  //         await File(f).delete();
  //       } catch (_) {}
  //     }
  //     await concatList.delete();
  //   } else {
  //     final failTrace = await session.getFailStackTrace();
  //     print("合并失败: code=$returnCode\nTrace: $failTrace");
  //     updateStatus(item.url, DownloadStatus.converfaild);
  //   }
  // }

  Future<void> deleteDownload(String url) async {
    final index = downloads.indexWhere((d) => d.url == url);
    if (index == -1) return;

    final item = downloads[index];
    final baseDir = await getDownloadDirectory();
    final episodeDir = Directory(p.join(baseDir, item.vodName, item.playTitle));

    if (await episodeDir.exists()) {
      try {
        await episodeDir.delete(recursive: true);
      } catch (e) {
        print("删除文件夹失败: $e");
      }
      final vodDir = Directory(p.join(baseDir, item.vodName));
      bool isVodDirEmpty = true;

      if (await vodDir.exists()) {
        final items = await vodDir.list().toList();
        isVodDirEmpty = items.isEmpty;
      }

      if (isVodDirEmpty) {
        try {
          await vodDir.delete();
        } catch (e) {
          print("删除文件夹失败: $e");
        }
      }
    }
    // 从下载列表中移除任务并保存
    downloads.removeAt(index);
    downloads.refresh();
    SPManager.saveDownloads(downloads);
    SPManager.removeProgress(item.localPath ?? '');
    _startNextIfPossible();
  }

  List<DownloadItem> getCurrentVodEpisodes(String vodId) {
    final list = downloads.where((e) => e.vodId == vodId).toList()
      ..sort((a, b) => a.playIndex.compareTo(b.playIndex)); // 保证按剧集顺序
    return list;
  }

  bool checkTaskAllDone() {
    return downloads.every((d) => d.status.value == DownloadStatus.completed);
  }
}
