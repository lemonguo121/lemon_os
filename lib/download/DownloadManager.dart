import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../http/data/DownloadTaskBean.dart';
import '../util/CommonUtil.dart';

class DownloadManager {
  // 单例
  static final DownloadManager _instance = DownloadManager._internal();

  factory DownloadManager() => _instance;

  DownloadManager._internal() {
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback); // 注册回调
    loadTasks();
  }

  final List<DownloadTaskBean> _tasks = [];
  final ReceivePort _port = ReceivePort();

  // 添加一个回调函数
  void Function()? onProgressUpdate;

  // 绑定后台Isolate
  void _bindBackgroundIsolate() {
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      int status = data[1];
      int progress = data[2];

      for (var task in _tasks) {
        if (task.id.toString() == id) {
          task.setStatus = status.toString();
          task.setProgress = progress;
          print("下载进度更新: id=$id, progress=$progress");
          // 在进度更新时，调用回调函数更新 UI
          if (onProgressUpdate != null) {
            onProgressUpdate!();
          }
        }
      }
    });
  }

  // 解绑后台Isolate
  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  // 下载回调函数
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? sendPort =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    print(
        "downloadCallback triggered: id=$id, status=$status, progress=$progress");
    sendPort?.send([id, status, progress]);
  }

  // 初始化方法
  Future<void> initialize() async {
    print("DownloadManager 初始化完成");
    // 如果需要，可以在这里初始化数据库或其他资源
  }

  // 请求存储权限
  Future<void> requestPermission() async {
    await Permission.storage.request();
  }

  // 启动下载
  // 启动下载
  Future<void> startDownload(String url, String fileName) async {
    // 1. 确保权限
    await Permission.storage.request();

    // 2. 获取下载路径
    final directory = await getExternalStorageDirectory();
    if (directory != null) {
      String savedDir = "${directory.path}/Download";
      print("savedDir: $savedDir");
    } else {
      print("无法获取下载目录！");
    }
    String savedDir = "${directory?.path}/Download";
    print("startDownload savedDir = $savedDir");

    // 3. 确保目录存在
    final savedDirPath = Directory(savedDir);
    if (!savedDirPath.existsSync()) {
      savedDirPath.createSync(recursive: true); // 递归创建目录
    }

    // 4. 判断任务列表是否已存在相同任务
    if (_tasks.any((task) => task.url == url)) {
      print("任务已存在，跳过添加");
      CommonUtil.showToast("任务已存在");
      return; // 如果任务已存在，直接返回
    }

    // 5. 下载 m3u8 文件
    final m3u8Content = await fetchM3u8File(url);
    print("startDownload m3u8Content = $m3u8Content");
    final tsUrls = parseM3u8(m3u8Content);

    // 创建下载任务对象
    DownloadTaskBean task = DownloadTaskBean(
      id: DateTime.now().millisecondsSinceEpoch,
      name: fileName,
      progress: 0,
      url: url,
      status: "0",
      savedPath: fileName, // 初始进度
    );

    // 将任务添加到任务列表
    _tasks.add(task);
    print("任务已添加到列表");

    // 6. 下载 .ts 文件
    await downloadTsFiles(tsUrls,fileName,savedDir);

    // // 7. 合并 .ts 文件为一个完整的视频
    // await mergeTsFiles(savedDir);
  }

  // 获取 m3u8 文件内容
  Future<String> fetchM3u8File(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body; // 返回 m3u8 文件内容
    } else {
      throw Exception('Failed to load m3u8 file');
    }
  }

  // 解析 m3u8 文件，提取所有 ts 文件的 URL
  List<String> parseM3u8(String m3u8Content) {
    final List<String> tsUrls = [];
    final lines = m3u8Content.split('\n');

    for (var line in lines) {
      final regex = RegExp(r'https?://[^\s]+\.ts(\?[^\s]*)?');
      if (regex.hasMatch(line)) {
        tsUrls.add(line); // 收集所有 .ts 文件的 URL
      }
      print("startDownload line = $line tsUrls = ${tsUrls.length}");
    }

    return tsUrls;
  }

// 下载 .ts 文件
  Future<void> downloadTsFiles(List<String> tsUrls, String fileName, String downloadDir) async {
    List<Future> downloadTasks = [];
    for (var i = 0; i < tsUrls.length; i++) {
      final tsUrl = tsUrls[i];
      final savePath = '$downloadDir/$fileName$i.ts';

      // 创建下载任务
      var task = FlutterDownloader.enqueue(
        url: tsUrl,
        savedDir: downloadDir,
        fileName: savePath,
        showNotification: true,
        openFileFromNotification: false,
      );

      downloadTasks.add(task);
    }

    // 等待所有下载任务完成
    await Future.wait(downloadTasks);
    print("所有 .ts 文件下载完成，开始合并");

    // 下载完成后，开始合并文件
    await mergeTsFiles(downloadDir,fileName);
  }

  // 合并所有 .ts 文件
  Future<void> mergeTsFiles(String downloadDir, String fileName) async {
    final fileList = Directory(downloadDir)
        .listSync()
        .where((entity) => entity.path.endsWith('.ts'))
        .toList();

    final fileListFile = File('$downloadDir/file_list.txt');
    final fileListContent =
        fileList.map((file) => "file '${file.path}'").join('\n');
    await fileListFile.writeAsString(fileListContent);

    String outputFilePath = '$downloadDir/$fileName.mp4';

    FFmpegKit.execute(
      '-f concat -safe 0 -i ${fileListFile.path} -c copy $outputFilePath',
    ).then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print('✅ 视频合并成功: $outputFilePath');
      } else {
        print('❌ 视频合并失败');
      }
    });
  }

  // 暂停下载任务
  Future<void> pauseTask(int id) async {
    await FlutterDownloader.pause(taskId: "$id");
  }

  // 恢复下载任务
  Future<void> resumeTask(int id) async {
    await FlutterDownloader.resume(taskId: "$id");
  }

  // 取消下载任务
  Future<void> cancelTask(int id) async {
    await FlutterDownloader.cancel(taskId: "$id");
    _tasks.removeWhere((task) => task.id == id);
  }

  // 从 SharedPreferences 中加载任务
  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskData = prefs.getStringList('tasks');
    if (taskData != null) {
      for (var taskString in taskData) {
        _tasks.add(DownloadTaskBean.fromString(taskString));
      }
    }
  }

  // 将任务保存到 SharedPreferences
  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskData = _tasks.map((task) => task.toString()).toList();
    prefs.setStringList('tasks', taskData);
  }

  // 获取当前所有下载任务
  List<DownloadTaskBean> get tasks => _tasks;
}
