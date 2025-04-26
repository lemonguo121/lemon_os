import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadManager {
  final Dio _dio = Dio();

  Future<String> _getDownloadDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${directory.path}/downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create();
    }
    return downloadDir.path;
  }

  // 下载歌曲并支持下载进度
  Future<String> downloadSong(String url, String songName, Function(int, int) onDownloadProgress) async {
    try {
      final downloadDir = await _getDownloadDir();
      final filePath = '$downloadDir/$songName.mp3';

      // 检查文件是否已存在
      final file = File(filePath);
      if (await file.exists()) {
        print('Song already downloaded.');
        return filePath;
      }

      print('Downloading song: $songName...');
      final response = await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onDownloadProgress(received, total);
          }
        },
      );
      print('Song downloaded: $filePath');
      return filePath;
    } catch (e) {
      print('Download error: $e');
      rethrow;
    }
  }

  // 获取已下载的歌曲列表
  Future<List<String>> getDownloadedSongs() async {
    final downloadDir = await _getDownloadDir();
    final directory = Directory(downloadDir);
    final files = directory.listSync();
    return files.map((file) => file.path.split('/').last.replaceAll('.mp3', '')).toList();
  }

  // 保存已下载的歌曲到播放列表
  Future<void> saveSongToPlaylist(String songName) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> playlist = prefs.getStringList('playlist') ?? [];
    if (!playlist.contains(songName)) {
      playlist.add(songName);
      await prefs.setStringList('playlist', playlist);
    }
  }

  // 获取本地播放列表
  Future<List<String>> getPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('playlist') ?? [];
  }
}
