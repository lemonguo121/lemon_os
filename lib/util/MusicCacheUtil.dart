import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MusicCacheUtil {
  /// 获取缓存目录（平台 + 类型）
  static Future<String> _getBasePath() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  /// 获取缓存文件路径
  static Future<File> _getFile(String id, String platform, String ext) async {
    final base = await _getBasePath();
    return File('$base/music_cache/${platform}_$id.$ext');
  }

  static Future<File> _getLyricFile(String id, String platform) async {
    final base = await _getBasePath();
    return File('$base/lyric_cache/${platform}_$id.lrc');
  }

  /// 检查是否有音频缓存
  static Future<bool> hasAudioCache(String id, String platform) async {
    final file = await _getFile(id, platform, 'mp3');
    return file.exists();
  }

  /// 检查是否有歌词缓存
  static Future<bool> hasLyricCache(String id, String platform) async {
    final file = await _getLyricFile(id, platform);
    return file.exists();
  }

  /// 是否有音频+歌词缓存
  static Future<bool> hasCache(String id, String platform) async {
    return await hasAudioCache(id, platform) && await hasLyricCache(id, platform);
  }

  /// 获取缓存的音频文件
  static Future<File> getCachedFile(String id, String platform) async {
    return _getFile(id, platform, 'mp3');
  }

  /// 获取缓存的歌词内容
  static Future<String> getCachedLyric(String id, String platform) async {
    final file = await _getLyricFile(id, platform);
    return file.existsSync() ? await file.readAsString() : '';
  }

  /// 下载并缓存音频
  static Future<void> downloadAndCache(String url, String id, String platform) async {
    final file = await _getFile(id, platform, 'mp3');
    await file.create(recursive: true);
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(Uri.parse(url));
    final response = await request.close();
    await response.pipe(file.openWrite());
  }

  /// 缓存歌词
  static Future<void> saveLyric(String lyric, String id, String platform) async {
    final file = await _getLyricFile(id, platform);
    await file.create(recursive: true);
    await file.writeAsString(lyric);
  }
}