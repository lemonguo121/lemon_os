import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/util/ThemeController.dart';
import 'package:photo_manager/photo_manager.dart';

import '../player/LocalVideoPlayerPage.dart';
import '../routes/routes.dart';

class VideoGalleryPage extends StatefulWidget {
  const VideoGalleryPage({super.key});

  @override
  State<VideoGalleryPage> createState() => _VideoGalleryPageState();
}

class _VideoGalleryPageState extends State<VideoGalleryPage> {
  final ThemeController themeController = Get.find();
  List<AssetEntity> videos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      fetchVideos();
    } else {
      PhotoManager.openSetting();
    }
  }

  Future<void> fetchVideos() async {
    setState(() => isLoading = true);

    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
    );
    if (albums.isNotEmpty) {
      videos = await albums.first.getAssetListRange(start: 0, end: 100);
    }

    setState(() => isLoading = false);
  }

  Future<void> playVideo(AssetEntity video) async {
    // var file = await video.file;
    // if (file != null) {
    //   Routes.goLocalVideoPage(file);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          appBar: AppBar(
            title: Text(
              "本地视频列表",
              style: TextStyle(
                  color: themeController.currentAppTheme.normalTextColor),
            ),
            iconTheme: IconThemeData(
                color: themeController.currentAppTheme.normalTextColor),
          ),
          body: isLoading
              ? Center(child: CircularProgressIndicator())
              : videos.isEmpty
                  ? Center(
                      child: Text(
                      "没有找到视频",
                      style: TextStyle(
                          color: themeController
                              .currentAppTheme.selectedTextColor),
                    ))
                  : GridView.builder(
                      padding: EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        return FutureBuilder<Uint8List?>(
                          future: videos[index]
                              .thumbnailDataWithSize(ThumbnailSize(200, 200)),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return Container(color: Colors.grey);
                            return GestureDetector(
                              onTap: () => playVideo(videos[index]),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(snapshot.data!,
                                      fit: BoxFit.cover),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.play_circle_fill,
                                          color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
        ));
  }
}
