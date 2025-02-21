import 'package:flutter/material.dart';

import 'DownloadManager.dart';

class DownloadManagerScreen extends StatefulWidget {
  @override
  _DownloadManagerScreenState createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends State<DownloadManagerScreen> {
  final downloadManager = DownloadManager();

  @override
  void initState() {
    super.initState();

    // 设置回调更新进度
    downloadManager.onProgressUpdate = () {
      print("DownloadManagerScreen onProgressUpdate");
      setState(() {});
    };

    // 加载任务并刷新 UI
    loadTasks();
  }

  // 加载任务列表
  void loadTasks() async {
    await downloadManager.loadTasks();
    setState(() {}); // 确保 UI 更新
  }

  @override
  Widget build(BuildContext context) {
    final tasks = downloadManager.tasks;
    print("任务列表 tasks = ${tasks.length}");

    return Scaffold(
      appBar: AppBar(title: Text("下载管理")),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task.name),
            subtitle: Text("进度: ${task.progress}%"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.pause),
                  onPressed: () => downloadManager.pauseTask(task.id),
                ),
                IconButton(
                  icon: Icon(Icons.play_arrow),
                  onPressed: () => downloadManager.resumeTask(task.id),
                ),
                IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () => downloadManager.cancelTask(task.id),
                ),
                if (task.progress == 100)
                  IconButton(
                    icon: Icon(Icons.play_circle),
                    onPressed: () => {}, // 完成后的操作
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
