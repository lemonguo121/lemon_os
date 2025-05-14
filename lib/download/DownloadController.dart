import 'dart:io';

import 'package:dio/dio.dart';
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
    if (item != null && item.status.value == DownloadStatus.downloading) {
      item.cancelToken.cancel("手动暂停");
      updateStatus(url, DownloadStatus.paused);
    }
  }

  void resumeDownload(String url) {
    final item = downloads.firstWhereOrNull((d) => d.url == url);
    if (item != null && item.status.value == DownloadStatus.paused) {
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
          .map((line) => line.trim()) // 去除空白字符，包括 \r、空格等
          .where((line) => !line.startsWith("#") && line.isNotEmpty)
          .toList();

      final dir = await getDownloadDirectory();
      final folder = p.join(dir, item.vodName, item.playTitle);
      await Directory(folder).create(recursive: true);
      updatefolder(url, folder);

      List<String> localSegmentPaths = []; // 用来记录每个切片的本地路径

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
          item.localSegments.add(savePath);
          localSegmentPaths.add(savePath); // 添加到本地路径列表
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

      // 生成 .m3u8 文件并保存
      final m3u8FilePath = p.join(folder, 'local.m3u8');
      await generateLocalM3u8(localSegmentPaths, m3u8FilePath);

      // 保存 m3u8 文件路径以便播放器使用
      final m3u8Uri = 'file://$m3u8FilePath';
      updateLocalPath(item.url, m3u8Uri);

      updateStatus(url, DownloadStatus.completed);
    } catch (e) {
      print("解析 m3u8 失败: $e");
      updateStatus(url, DownloadStatus.paused);
    }
  }

  Future<void> generateLocalM3u8(List<String> tsPaths, String savePath) async {
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');
    buffer.writeln('#EXT-X-VERSION:3');
    buffer.writeln('#EXT-X-TARGETDURATION:10');  // 每个切片的时长，可以根据实际情况修改
    buffer.writeln('#EXT-X-MEDIA-SEQUENCE:0');

    // 遍历每个 ts 文件，生成对应的 .m3u8 内容
    for (final ts in tsPaths) {
      buffer.writeln('#EXTINF:10.0,');  // 假设每个切片为 10 秒，实际可以根据需求调整
      buffer.writeln(p.basename(ts)); // 只写相对路径
    }

    buffer.writeln('#EXT-X-ENDLIST');

    // 将生成的内容写入 .m3u8 文件
    final file = File(savePath);
    await file.writeAsString(buffer.toString());
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
