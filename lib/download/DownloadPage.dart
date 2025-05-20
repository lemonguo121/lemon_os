import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/util/widget/LoadingImage.dart';

import '../routes/routes.dart';
import '../util/ThemeController.dart';
import 'DownloadController.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final downloadController = Get.find<DownloadController>();
  final ThemeController themeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: themeController.currentAppTheme.normalTextColor,
        ),
        title: Text(
          "下载管理",
          style:
              TextStyle(color: themeController.currentAppTheme.normalTextColor),
        ),
      ),
      body: Obx(() {
        final grouped =
            downloadController.groupedByVodName; // ✅ 从 controller 获取
        if (grouped.isEmpty) {
          return Center(child: Text("暂无下载"));
        }
        return  ListView.builder(
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final vodName = grouped.keys.elementAt(index);
              final items = grouped[vodName]!;
              final firstItem = items.first;
              return Card(
                color: themeController.currentAppTheme.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 18.h,horizontal: 22.w),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () {
                    Routes.goEpisodeListPage(vodName);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      height: 300.r,
                      child: Stack(
                        children: [
                          // 左侧渐变透明图片，只占 1/3 宽度
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 220.r, // 减去外部 padding
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.white,
                                  Colors.transparent,
                                ],
                              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                              blendMode: BlendMode.dstIn,
                              child: LoadingImage(
                                pic: firstItem.vodPic,
                              ),
                            ),
                          ),

                          // 内容文字部分，带右箭头
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 左边图片区域留出宽度，不显示图，只占位
                                SizedBox(width: 230.r),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vodName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 36.sp,
                                          color: themeController.currentAppTheme.normalTextColor,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        '共 ${items.length} 集',
                                        style: TextStyle(color:themeController.currentAppTheme.normalTextColor.withAlpha(200)),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
        );
      }),
    );
  }
}
