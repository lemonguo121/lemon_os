import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheUtil {
  /// 获取缓存大小 (返回 MB)
  static Future<double> getCacheSize() async {
    final cacheDir = await getTemporaryDirectory();

    final List<Directory> targetDirs = [
      Directory("${cacheDir.path}/libCachedImageData"), // flutter_cache_manager
      Directory("${cacheDir.path}/music_cache"),         // 歌曲缓存
      Directory("${cacheDir.path}/lyric_cache"),         // 歌词缓存
    ];

    int totalSize = 0;
    for (var dir in targetDirs) {
      if (dir.existsSync()) {
        totalSize += dir
            .listSync(recursive: true)
            .whereType<File>()
            .map((file) => file.lengthSync())
            .fold(0, (sum, length) => sum + length);
      }
    }

    return totalSize / 1024 / 1024; // MB
  }

  /// 清理缓存
  static Future<void> clearCache() async {
    final cacheDir = await getTemporaryDirectory();

    final List<Directory> targetDirs = [
      Directory("${cacheDir.path}/libCachedImageData"),
      Directory("${cacheDir.path}/music_cache"),
      Directory("${cacheDir.path}/lyric_cache"),
    ];

    for (var dir in targetDirs) {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    }
  }

  /// 清理缓存并返回清理后的大小
  static Future<double> clearAndGetCacheSize() async {
    await clearCache();
    return await getCacheSize();
  }
}
