import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lemon_tv/http/data/RealVideo.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../util/SPManager.dart';
import 'DownloadItem.dart';

class DownloadController extends GetxController {
  var downloads = <DownloadItem>[].obs;

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

    if (url.endsWith('.m3u8')) {
      _downloadM3u8(url);
    } else {
      _downloadVideo(url);
    }
    return true;
  }

  void pauseDownload(String url) {
    final item = downloads.firstWhereOrNull((d) => d.url == url);
    if (item != null && item.status == DownloadStatus.downloading) {
      item.cancelToken.cancel("手动暂停");
      updateStatus(url, DownloadStatus.paused);
    }
  }

  void resumeDownload(String url) {
    final item = downloads.firstWhereOrNull((d) => d.url == url);
    if (item != null && item.status == DownloadStatus.paused) {
      final newCancelToken = CancelToken();
      item.cancelToken = newCancelToken;
      updateStatus(url, DownloadStatus.downloading);

      if (url.endsWith('.m3u8')) {
        _downloadM3u8(url);
      } else {
        _downloadVideo(url);
      }
    }
  }

  void updateStatus(String url, DownloadStatus status) {
    final index = downloads.indexWhere((d) => d.url == url);
    if (index != -1) {
      downloads[index].status.value = status;
      downloads.refresh();
      SPManager.saveDownloads(downloads);

      WakelockPlus.toggle(enable: !checkTaskAllDone());
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

  Future<String> _getDownloadDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> _downloadVideo(String url) async {
    final item = downloads.firstWhereOrNull((d) => d.url == url);
    if (item == null) return;

    final dir = await _getDownloadDirectory();
    final filename = Uri.parse(url).pathSegments.last;

    // 构造路径：影片/剧集/文件名
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

  Future<void> _downloadM3u8(String url) async {
    final item = downloads.firstWhereOrNull((d) => d.url == url);
    if (item == null) return;

    var downloadedBytes = item.downloadedBytes;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        updateStatus(url, DownloadStatus.paused);
        return;
      }

      final lines = response.body.split('\n');
      final segmentUrls = lines
          .where((line) => !line.startsWith("#") && line.trim().isNotEmpty)
          .toList();

      final dir = await _getDownloadDirectory();
      final folder = p.join(dir, item.vodName, item.playTitle);
      await Directory(folder).create(recursive: true);
      updatefolder(url, folder);
      for (int i = item.currentIndex; i < segmentUrls.length; i++) {
        if (item.status == DownloadStatus.paused ||
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
          item.localSegments.add(savePath);
          item.currentIndex = i + 1;

          downloadedBytes += res.data!.length;
          final percent = ((i + 1) / segmentUrls.length * 100).toInt();
          updateProgress(url, percent, downloadedBytes);
        } catch (e) {
          print("下载切片失败: $segmentUrl - $e");
          updateStatus(url, DownloadStatus.paused);
          return;
        }
      }

      updateStatus(url, DownloadStatus.conversioning);
      await mergeSegments(item);
    } catch (e) {
      print("解析 m3u8 失败: $e");
      updateStatus(url, DownloadStatus.paused);
    }
  }

  Future<void> mergeSegments(DownloadItem item) async {
    String folder = item.folder ?? '';
    final concatList = File(p.join(folder, 'input.txt'));
    await concatList.writeAsString(
      item.localSegments.map((p) => "file '$p'").join('\n'),
    );

    final outputPath = p.join(folder, '${item.vodName}_${item.playTitle}.mp4');

    final session = await FFmpegKit.execute(
        "-f concat -safe 0 -i '${concatList.path}' -fflags +genpts -movflags +faststart -avoid_negative_ts make_zero -c copy '$outputPath'");

    final returnCode = await session.getReturnCode();
    final logs = await session.getAllLogs();
    for (final log in logs) {
      print("FFmpeg Log: ${log.getMessage()}");
    }

    if (ReturnCode.isSuccess(returnCode)) {
      updateLocalPath(item.url, outputPath);
      updateStatus(item.url, DownloadStatus.completed);

      for (final f in item.localSegments) {
        try {
          await File(f).delete();
        } catch (_) {}
      }
      await concatList.delete();
    } else {
      final failTrace = await session.getFailStackTrace();
      print("合并失败: code=$returnCode\nTrace: $failTrace");
      updateStatus(item.url, DownloadStatus.converfaild);
    }
  }

  // GTP 说flutter_download不适合下载ts很多的情况，代码先保存，后面再结合实际使用看到底要不要继续开发flutter_download的使用，目前还是使用dio算了
  // Future<void> _downloadM3u8(String url) async {
  //   final item = downloads.firstWhereOrNull((d) => d.url == url);
  //   if (item == null) return;
  //
  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     if (response.statusCode != 200) {
  //       updateStatus(url, DownloadStatus.paused);
  //       return;
  //     }
  //
  //     final lines = response.body.split('\n');
  //     final segmentUrls = lines
  //         .where((line) => !line.startsWith("#") && line.trim().isNotEmpty)
  //         .toList();
  //
  //     final dir = await _getDownloadDirectory();
  //     final folder = p.join(dir, item.vodName, item.playTitle);
  //     await Directory(folder).create(recursive: true);
  //     updatefolder(url, folder);
  //
  //     // 存储 taskId 和路径的映射
  //     final taskIdToPath = <String, String>{};
  //     final taskIdToIndex = <String, int>{};
  //
  //     item.localSegments.clear();
  //     item.currentIndex = 0;
  //     item.segmentCount = segmentUrls.length;
  //
  //     for (int i = 0; i < segmentUrls.length; i++) {
  //       final segmentUrl = Uri.parse(segmentUrls[i]).isAbsolute
  //           ? segmentUrls[i]
  //           : Uri.parse(url).resolve(segmentUrls[i]).toString();
  //
  //       final fileName = 'segment_$i.ts';
  //       final taskId = await FlutterDownloader.enqueue(
  //         url: segmentUrl,
  //         savedDir: folder,
  //         fileName: fileName,
  //         showNotification: false,
  //         openFileFromNotification: false,
  //       );
  //
  //       if (taskId != null) {
  //         taskIdToPath[taskId] = p.join(folder, fileName);
  //         taskIdToIndex[taskId] = i;
  //         item.pendingTaskIds.add(taskId);
  //       }
  //     }
  //
  //     item.taskIdToPath = taskIdToPath;
  //     item.taskIdToIndex = taskIdToIndex;
  //     updateStatus(url, DownloadStatus.downloading);
  //   } catch (e) {
  //     print("解析 m3u8 失败: $e");
  //     updateStatus(url, DownloadStatus.paused);
  //   }
  // }
  //
  //  void downloadCallback(String id, DownloadTaskStatus status, int progress) async {
  //   final item = downloads.firstWhereOrNull((d) => d.pendingTaskIds.contains(id));
  //   if (item == null) return;
  //
  //   if (status == DownloadTaskStatus.complete) {
  //     final savePath = item.taskIdToPath[id];
  //     final index = item.taskIdToIndex[id];
  //     if (savePath != null && index != null) {
  //       // 保证顺序
  //       item.localSegments.add(savePath);
  //       item.currentIndex++;
  //
  //       // 计算进度
  //       final percent = ((item.currentIndex) / item.segmentCount * 100).toInt();
  //       updateProgress(item.url, percent, null);
  //     }
  //
  //     // 判断是否全部完成
  //     if (item.currentIndex >= item.segmentCount) {
  //       updateStatus(item.url, DownloadStatus.conversioning);
  //       await mergeSegments(item);
  //     }
  //   } else if (status == DownloadTaskStatus.failed) {
  //     updateStatus(item.url, DownloadStatus.paused);
  //   }
  // }

  Future<void> deleteDownload(String url) async {
    final index = downloads.indexWhere((d) => d.url == url);
    if (index == -1) return;

    final item = downloads[index];
    final baseDir = await _getDownloadDirectory();
    final episodeDir = Directory(p.join(baseDir, item.vodName, item.playTitle));

    if (await episodeDir.exists()) {
      try {
        await episodeDir.delete(recursive: true);
        print("删除文件夹: ${episodeDir.path}");
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
          print("删除空的文件夹: ${vodDir.path}");
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
