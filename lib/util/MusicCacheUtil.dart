import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicCacheUtil {
  static Future<void> ensureStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();

      if (status.isDenied || status.isPermanentlyDenied) {
        throw Exception('请在设置中手动开启存储权限');
      }
    }
  }

  /// 获取缓存基础目录（Android 使用外部可见目录，其他平台用文档目录）
  static Future<String> _getBasePath() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/LM_Player');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
  }

  /// 获取音频缓存文件路径
  static Future<File> _getFile(
      String name, String id, String platform, String ext) async {
    final base = await _getBasePath();
    final fileName = '${name}_${platform}_$id.$ext';
    return File('$base/music_cache/$fileName');
  }

  /// 获取歌词缓存文件路径
  static Future<File> _getLyricFile(
      String name, String id, String platform) async {
    final base = await _getBasePath();
    final fileName = '${name}_${platform}_$id.lrc';
    return File('$base/lyric_cache/$fileName');
  }

  /// 是否有音频缓存
  static Future<bool> hasAudioCache(
      String name, String id, String platform) async {
    final file = await _getFile(name, id, platform, 'mp3');
    return file.exists();
  }

  /// 是否有歌词缓存
  static Future<bool> hasLyricCache(
      String name, String id, String platform) async {
    final file = await _getLyricFile(name, id, platform);
    return file.exists();
  }

  /// 是否有音频+歌词缓存
  static Future<bool> hasCache(String name, String id, String platform) async {
    return await hasAudioCache(name, id, platform) &&
        await hasLyricCache(name, id, platform);
  }

  /// 获取缓存的音频文件
  static Future<File> getCachedFile(
      String name, String id, String platform) async {
    return _getFile(name, id, platform, 'mp3');
  }

  /// 获取缓存的歌词内容
  static Future<String> getCachedLyric(
      String name, String id, String platform) async {
    final file = await _getLyricFile(name, id, platform);
    return file.existsSync() ? await file.readAsString() : '';
  }

  /// 下载并缓存音频
  static Future<void> downloadAndCache(
      String url, String name, String id, String platform) async {
    final file = await _getFile(name, id, platform, 'mp3');
    await file.create(recursive: true);
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(Uri.parse(url));
    final response = await request.close();
    await response.pipe(file.openWrite());
  }

  /// 缓存歌词
  static Future<void> saveLyric(
      String lyric, String name, String id, String platform) async {
    final file = await _getLyricFile(name, id, platform);
    await file.create(recursive: true);
    await file.writeAsString(lyric);
  }

  /// 删除音频缓存
  static Future<void> deleteAudioCache(
      String name, String id, String platform) async {
    final file = await _getFile(name, id, platform, 'mp3');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 删除歌词缓存
  static Future<void> deleteLyricCache(
      String name, String id, String platform) async {
    final file = await _getLyricFile(name, id, platform);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 删除某首歌的全部缓存
  static Future<void> deleteAllCacheForSong(
      String name, String id, String platform) async {
    await deleteAudioCache(name, id, platform);
    await deleteLyricCache(name, id, platform);
  }
}
