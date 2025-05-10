import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import '../util/SPManager.dart';
import 'DownloadItem.dart';

class DownloadController extends GetxController {
  var downloads = <DownloadItem>[].obs;

  final Dio dio = Dio();

  void startDownload(String url) {
    if (downloads.any((d) => d.url == url)) {
      print("任务已存在: $url");
      return;
    }

    final cancelToken = CancelToken();
    final newItem = DownloadItem(
      url: url,
      progress: 0,
      status: DownloadStatus.downloading,
      localPath: '',
      cancelToken: cancelToken,
      currentIndex: 0,
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

  void deleteDownload(String url) {
    final index = downloads.indexWhere((d) => d.url == url);
    if (index != -1) {
      downloads.removeAt(index);
      downloads.refresh();
      SPManager.saveDownloads(downloads);
    }
  }

  void updateStatus(String url, DownloadStatus status) {
    final index = downloads.indexWhere((d) => d.url == url);
    if (index != -1) {
      downloads[index].status = status;
      downloads.refresh();
      SPManager.saveDownloads(downloads);
    }
  }

  void updateProgress(String url, int progress) {
    final index = downloads.indexWhere((d) => d.url == url);
    if (index != -1) {
      downloads[index].progress = progress;
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

  Future<String> _getDownloadDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> _downloadVideo(String url) async {
    final item = downloads.firstWhereOrNull((d) => d.url == url);
    if (item == null) return;

    final dir = await _getDownloadDirectory();
    final filename = Uri.parse(url).pathSegments.last;
    final savePath = p.join(dir, filename);
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
            updateProgress(url, progress);
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
      final folder = p.join(dir, 'm3u8_${url.hashCode}');
      await Directory(folder).create(recursive: true);

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

          final percent = ((i + 1) / segmentUrls.length * 100).toInt();
          updateProgress(url, percent);
        } catch (e) {
          print("下载切片失败: $segmentUrl - $e");
          updateStatus(url, DownloadStatus.paused);
          return;
        }
      }

      // 合并
      final concatList = File(p.join(folder, 'input.txt'));
      await concatList.writeAsString(
        item.localSegments.map((p) => "file '$p'").join('\n'),
      );

      final outputPath = p.join(folder, 'output.mp4');
      await FFmpegKit.execute(
          "-f concat -safe 0 -i '${concatList.path}' -c copy '$outputPath'");
      updateLocalPath(url, outputPath);
      updateStatus(url, DownloadStatus.completed);

      // 删除 TS 切片
      for (final f in item.localSegments) {
        try {
          await File(f).delete();
        } catch (_) {}
      }
      await concatList.delete();
    } catch (e) {
      print("解析 m3u8 失败: $e");
      updateStatus(url, DownloadStatus.paused);
    }
  }
}
