import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';

import 'DownloadItem.dart';

class DownloadController extends GetxController {
  final RxList<DownloadItem> downloads = <DownloadItem>[].obs;

  void startDownload(String url) {
    print("下载任务启动: $url");
    final exists = downloads.any((d) => d.url == url);
    if (!exists) {
      downloads.add(DownloadItem(url: url));
      print("添加新的下载任务: $url");
    } else {
      print("任务已存在，跳过添加: $url");
    }

    if (url.endsWith(".m3u8")) {
      _downloadM3u8(url);
    } else {
      _downloadVideo(url);
    }
  }

  Future<String> _getDownloadDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> _downloadVideo(String url) async {
    print("开始下载视频: $url");
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await _getDownloadDirectory();
        final filename = Uri.parse(url).pathSegments.last;
        final file = File(p.join(dir, filename));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        updateStatus(url, DownloadStatus.completed);
        print("视频下载完成: ${file.path}");
      } else {
        print("视频下载失败: HTTP ${response.statusCode}");
        updateStatus(url, DownloadStatus.paused);
      }
    } catch (e) {
      print("下载视频失败: $e");
      updateStatus(url, DownloadStatus.paused);
    }
  }

  Future<void> _downloadM3u8(String url) async {
    print("解析 m3u8 开始: $url");
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        print("获取 m3u8 文件失败: HTTP ${response.statusCode}");
        return;
      }

      final lines = response.body.split('\n');
      final segmentUrls = lines.where((line) => !line.startsWith("#") && line.trim().isNotEmpty).toList();

      final dir = await _getDownloadDirectory();
      final folder = p.join(dir, 'm3u8_downloads', DateTime.now().millisecondsSinceEpoch.toString());
      await Directory(folder).create(recursive: true);

      List<String> localSegments = [];

      for (int i = 0; i < segmentUrls.length; i++) {
        final segmentUrl = segmentUrls[i];
        final fullUrl = Uri.parse(segmentUrl).isAbsolute ? segmentUrl : Uri.parse(url).resolve(segmentUrl).toString();
        final localPath = p.join(folder, 'segment_$i.ts');
        await _downloadSegment(fullUrl, localPath);
        localSegments.add(localPath);
        final percent = ((i + 1) / segmentUrls.length * 100).toInt();
        updateProgress(url, percent);
      }

      final outputPath = p.join(folder, 'output.mp4');
      final concatList = p.join(folder, 'input.txt');

      final concatFile = File(concatList);
      await concatFile.writeAsString(localSegments.map((path) => "file '$path'").join('\n'));

      print("合并 ts 文件为 mp4: $outputPath");
      await FFmpegKit.execute(
        "-f concat -safe 0 -i '$concatList' -c copy '$outputPath'",
      );

      updateStatus(url, DownloadStatus.completed);
      print("视频合并完成: $outputPath");

    } catch (e) {
      print("解析或下载 m3u8 失败: $e");
      updateStatus(url, DownloadStatus.paused);
    }
  }

  Future<void> _downloadSegment(String url, String savePath) async {
    print("下载切片: $url");
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final file = File(savePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception("下载失败: $url");
    }
  }

  void updateProgress(String url, int progress) {
    print("更新下载进度: $url - ${progress}%");
    int index = downloads.indexWhere((d) => d.url == url);
    if (index != -1) {
      downloads[index] = downloads[index].copyWith(progress: progress);
      downloads.refresh();
    }
  }

  void updateStatus(String url, DownloadStatus status) {
    print("更新下载状态: $url - ${status.name}");
    int index = downloads.indexWhere((d) => d.url == url);
    if (index != -1) {
      downloads[index] = downloads[index].copyWith(status: status);
      downloads.refresh();
    }
  }

  void pauseDownload(String url) {
    print("暂停下载: $url");
    updateStatus(url, DownloadStatus.paused);
  }
}