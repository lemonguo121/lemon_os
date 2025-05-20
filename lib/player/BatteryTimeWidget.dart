import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lemon_tv/download/DownloadController.dart';
import 'package:lemon_tv/player/controller/VideoPlayerGetController.dart';
import 'package:lemon_tv/util/CommonUtil.dart';


class BatteryTimeWidget extends StatefulWidget {
  final bool isFullScreen;

  const BatteryTimeWidget({super.key, required this.isFullScreen});

  @override
  _BatteryTimeWidgetState createState() => _BatteryTimeWidgetState();
}

class _BatteryTimeWidgetState extends State<BatteryTimeWidget> {
  VideoPlayerGetController controller = Get.find();
  DownloadController downloadController = Get.find();
  final Battery _battery = Battery();

  String _timeString = "";
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _getBatteryStatus();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateTime();
        _getBatteryStatus();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// 获取当前时间
  void _updateTime() {
    if (mounted) {}
    setState(() {
      _timeString = DateFormat('HH:mm').format(DateTime.now());
    });
  }

  /// 获取电量
  Future<void> _getBatteryStatus() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final batteryLevel = await _battery.batteryLevel;
      controller.batteryLevel.value = batteryLevel;
    }
  }

  /// 获取电池颜色
  Color _getBatteryColor() {
    if (controller.batteryLevel.value > 20) return Colors.green;
    if (controller.batteryLevel.value > 10) return Colors.orange;
    return Colors.red; // 低电量警告
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFullScreen || !(Platform.isAndroid || Platform.isIOS)) {
      return const SizedBox.shrink(); // 桌面端隐藏
    }
    var isVertical = CommonUtil.isVertical();
    return Obx(() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNetWorkType(),
            SizedBox(width: 16.w),
            // 当前时间
            Text(
              _timeString,
              style: TextStyle(
                color: Colors.white,
                fontSize: isVertical ? 18.sp : 14.sp,
              ),
            ),
            SizedBox(width: 16.w),

            // 水平电池样式
            Container(
              width: isVertical ? 39.w : 24.w, // 电池整体宽度
              height: isVertical ? 20.h : 28.h, // 电池整体高度
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5.w), // 边框
                borderRadius: BorderRadius.circular(3.r), // 圆角
              ),
              child: Stack(
                alignment: Alignment.center, // 这里确保子元素居中
                children: [
                  // 电池进度条
                  Positioned(
                    left: 1.0.w,
                    right: 1.0.w,
                    top: 1.0.h,
                    bottom: 1.0.h,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: controller.batteryLevel.value / 100,
                      // 计算电池电量
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getBatteryColor(),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                  ),
                  // 显示电量数值
                  Text(
                    '${controller.batteryLevel.value}', // 显示电池百分比
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isVertical ? 13.sp : 7.sp,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // 电池头部
            Container(
              width: 3, // 电池突出部分
              height: 6,
              margin: EdgeInsets.only(left: 1.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1.r),
              ),
            ),
          ],
        ));
  }

  Widget _buildNetWorkType() {
    final status = downloadController.connectionStatus.isNotEmpty
        ? downloadController.connectionStatus.first
        : ConnectivityResult.none;
    switch (status) {
      case ConnectivityResult.wifi:
        return Icon(Icons.wifi, color: Colors.white);
      case ConnectivityResult.mobile:
        return Icon(Icons.signal_cellular_alt, color: Colors.white);
      case ConnectivityResult.none:
        return Icon(Icons.signal_wifi_off, color: Colors.grey);
      default:
        return Icon(Icons.wifi, color: Colors.white);
    }
  }
}
