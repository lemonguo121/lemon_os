import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/music_home/music_home_controller.dart';
import 'package:lemon_tv/util/widget/NoDataView.dart';

import '../../../../routes/routes.dart';
import '../../player/music_controller.dart';

class TopListContentView extends StatefulWidget {
  final String id;

  const TopListContentView({Key? key, required this.id}) : super(key: key);

  @override
  State<TopListContentView> createState() => _TopListContentViewState();
}

class _TopListContentViewState extends State<TopListContentView> {
  final MusicHomeController controller = Get.find();
  final MusicPlayerController playerController = Get.find();
  @override
  void initState() {
    super.initState();
    print('******${widget.id}');
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.subModel.value.musicList.isEmpty) {
        return  NoDataView(
          reload: load,
          errorTips: '暂无数据，点击刷新',);
      }
      return ListView.builder(
        itemCount: controller.subModel.value.musicList.length,
        itemBuilder: (context, index) {
          final item = controller.subModel.value.musicList[index];
          return GestureDetector(
            onTap:(){
              final songId = item.id;
              final songName = item.artist;
              if (songId != null) {
                playerController.upDataSong(item);
                Routes.goMusicPage();
              }
            },
            child: ListTile(
              title: Text(item.title ?? ''),
              subtitle: Text(item.artist ?? ''),
            ),
          );
        },
      );
    });
  }

  void load() {
    controller.getHotList(id: widget.id);
  }
}