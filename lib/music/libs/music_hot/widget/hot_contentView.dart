import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/libs/player/music_controller.dart';

import '../../../../routes/routes.dart';
import '../../../music_http/music_http_rquest.dart';
import '../../../music_utils/MusicSPManage.dart';
import '../hot_controller.dart';

class TopListContentView extends StatefulWidget {
  final String id;

  const TopListContentView({Key? key, required this.id}) : super(key: key);

  @override
  State<TopListContentView> createState() => _TopListContentViewState();
}

class _TopListContentViewState extends State<TopListContentView> {
  final HotController controller = Get.find();
  final MusicPlayerController playerController = Get.find();
  @override
  void initState() {
    super.initState();
    print('******${widget.id}');
    controller.getHotList(id: widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
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
                playerController.upDateSong(item);
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
}