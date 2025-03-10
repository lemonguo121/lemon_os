import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheUtil {
  /// 获取缓存大小 (返回 MB)
  static Future<double> getCacheSize() async {
    Directory cacheDir = await getTemporaryDirectory();
    Directory customCacheDir = Directory("${cacheDir.path}/libCachedImageData");

    if (customCacheDir.existsSync()) {
      int totalSize = customCacheDir
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.lengthSync())
          .fold(0, (sum, length) => sum + length);

      return totalSize / 1024 / 1024; // 转换为 MB
    }
    return 0;
  }

  /// 清理缓存
  static Future<void> clearCache() async {
    Directory cacheDir = await getTemporaryDirectory();
    Directory customCacheDir = Directory("${cacheDir.path}/libCachedImageData");
    if (customCacheDir.existsSync()) {
      await customCacheDir.delete(recursive: true);
      await customCacheDir.create(recursive: true);
    }
  }

  /// 清理缓存并返回清理后的大小
  static Future<double> clearAndGetCacheSize() async {
    await clearCache();
    return await getCacheSize();
  }
}
