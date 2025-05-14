import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart' as p;

class LocalHttpServer {
  static HttpServer? _server;

  /// 启动服务，监听指定目录
  static Future<void> start(String directoryPath, {int port = 12345}) async {
    if (_server != null) {
      return;
    }
    final handler = createStaticHandler(
      directoryPath,
      defaultDocument: 'index.html',
      serveFilesOutsidePath: true,
    );

    try {
      _server = await io.serve(handler, InternetAddress.loopbackIPv4, port);
    } catch (e) {
      print('❌ 启动服务失败: $e');
    }
  }

  /// 关闭服务（如需）
  static Future<void> stop() async {
    await _server?.close();
    _server = null;
  }
}
