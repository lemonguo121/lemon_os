import 'package:flutter/material.dart';
import 'music_download.dart'; // 导入下载管理器

class MusicRecord extends StatefulWidget {
  const MusicRecord({super.key});

  @override
  State<MusicRecord> createState() => _MusicRecordState();
}

class _MusicRecordState extends State<MusicRecord> {
  late DownloadManager _downloadManager;
  late Future<List<String>> _downloadedSongs;

  @override
  void initState() {
    super.initState();
    _downloadManager = DownloadManager();
    _downloadedSongs = _downloadManager.getDownloadedSongs(); // 获取已下载的歌曲列表
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的音乐记录')),
      body: FutureBuilder<List<String>>(
        future: _downloadedSongs, // 等待异步获取下载列表
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // 等待加载时显示加载动画
          }

          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }

          final downloadedSongs = snapshot.data ?? [];

          if (downloadedSongs.isEmpty) {
            return const Center(child: Text('没有下载的歌曲'));
          }

          return ListView.builder(
            itemCount: downloadedSongs.length,
            itemBuilder: (context, index) {
              final songName = downloadedSongs[index];
              return ListTile(
                title: Text(songName),
                onTap: () {
                  // 点击歌曲后，可以进行播放或者其他操作
                  print("点击了歌曲: $songName");
                },
              );
            },
          );
        },
      ),
    );
  }
}
