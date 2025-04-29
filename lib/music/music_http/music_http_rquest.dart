import 'package:dio/dio.dart';
import 'package:lemon_tv/music/music_utils/MusicSPManage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();

  factory NetworkManager() => _instance;
  late Dio _dio;

//  •	搜索: 通过访问 http://192.168.2.1:1000/search?query=周杰伦&plugin=aiting&type=album&page=1
//  query:内容；
//  plugin:插件名；
//  type：搜索类型（music：音乐；album：专辑；artist：作者；sheet：歌单）
//  page：页码
//  •	获取歌词: 通过访问 https://music-plugings.onrender.com/lyric?id=bWhuZGt2bWg（假设 bWhuZGt2bWg 是一个有效的歌曲 ID）
//  •	获取排行榜: 通过访问 https://music-plugings.onrender.com/getTopLists?id=new&plugin=aiting
//  •	获取榜单详情: 通过访问 https://music-plugings.onrender.com/getTopListDetail?id=djwuqu&plugin=aiting
//  •	获取媒体信息: 通过访问 https://music-plugings.onrender.com/getMediaSource?id=bWhuZGt2bWg（假设 bWhuZGt2bWg 是一个有效的歌曲 ID）

  static String baseUrl = "http://192.168.2.1:1000"; // 将 baseUrl 设置为静态变量

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  NetworkManager._internal() {
    var storehouseBean = MusicSPManage.getCurrentSubscription();
    baseUrl = storehouseBean?.url??"";
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl, // 你的域名
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 拦截器（可选）
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('请求: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('响应: ${response.statusCode} ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('请求错误: $e');
        return handler.next(e);
      },
    ));
  }

  // GET 请求
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  // POST 请求（如果以后需要）
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<String?> downloadSong(String url, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/songs';

      // 创建文件夹
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final filePath = '$path/$fileName.mp3';
      final file = File(filePath);

      // 如果文件已存在，不下载
      if (await file.exists()) {
        return filePath;
      }

      await Dio().download(url, filePath);
      return filePath;
    } catch (e) {
      print('下载失败: $e');
      return null;
    }
  }
}
