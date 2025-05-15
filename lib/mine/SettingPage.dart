import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/music/player/music_controller.dart';
import 'package:lemon_tv/util/CommonUtil.dart';
import 'package:lemon_tv/util/SPManager.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import 'SettingController.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final ScrollController _scrollController = ScrollController();
  final settingController = Get.put(SettingController());
  MusicPlayerController playerController = Get.find();
  List<double> speedList = [2.0, 3.0, 4.0, 5.0];
  var _selecteIndex = 1;
  double longPressSpeed = 2.0;
  @override
  void initState() {
    super.initState();
    longPressSpeed = SPManager.getLongPressSpeed();
    _selecteIndex = speedList.indexOf(longPressSpeed);
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeController themeController = Get.find();
    return Obx(() => Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(
                color: themeController.currentAppTheme.normalTextColor),
            title: Text(
              '设置',
              style: TextStyle(
                  color: themeController.currentAppTheme.normalTextColor),
            ),
          ),
          body: Column(
            children: [
              ListTile(
                title: Text('长按倍速',
                    style: TextStyle(
                        color: themeController.currentAppTheme.titleColr)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$longPressSpeed',
                        style: TextStyle(
                            color: themeController.currentAppTheme.titleColr)),
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: themeController.currentAppTheme.titleColr,
                    )
                  ],
                ),
                onTap: (() => showSelectDialog()),
              ),
              ListTile(
                title: Text('是否开启media_kit',
                    style: TextStyle(
                        color: themeController.currentAppTheme.titleColr)),
                trailing: Switch(
                  value: settingController.enableKit.value,
                  onChanged: settingController.toggle,
                ),
              ),
              ListTile(
                title: Text('音乐音量',
                    style: TextStyle(
                        color: themeController.currentAppTheme.titleColr)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        '${(playerController.currentVolume.value * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                            color: themeController.currentAppTheme.titleColr)),
                    SizedBox(
                      width: 16,
                    ),
                    InkWell(
                      onTap: () {
                        playerController.adjustVolume(-5);
                      },
                      child: Text('音量-',
                          style: TextStyle(
                              color:
                                  themeController.currentAppTheme.titleColr)),
                    ),
                    SizedBox(
                      width: 16,
                    ),
                    InkWell(
                      onTap: () {
                        playerController.adjustVolume(5);
                      },
                      child: Text('音量+',
                          style: TextStyle(
                              color:
                                  themeController.currentAppTheme.titleColr)),
                    ),
                  ],
                ),
              )
            ],
          ),
        ));
  }

  showSelectDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        var dialogSize;
        if (CommonUtil.isVertical(context)) {
          dialogSize = CommonUtil.getScreenWidth(context) * 9 / 10;
        } else {
          dialogSize = CommonUtil.getScreenHeight(context) * 9 / 10;
        }

        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.all(16),
            height: dialogSize * 7 / 8,
            width: dialogSize,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "请选择长按时视频播放速度",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                      mainAxisExtent: 30,
                    ),
                    itemCount: speedList.length,
                    itemBuilder: (context, index) {
                      var speed = speedList[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selecteIndex = index;
                            longPressSpeed = speedList[_selecteIndex];
                            SPManager.setLongPressSpeed(longPressSpeed);
                          });
                          setModalState(() {});
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: _selecteIndex == index
                                  ? Colors.blueAccent
                                  : Colors.transparent,
                              border: Border.all(color: Colors.black45),
                              borderRadius: BorderRadius.circular(30.0)),
                          child: Text(
                            '$speed',
                            style: TextStyle(
                                color: _selecteIndex == index
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
