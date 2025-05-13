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
          style: TextStyle(
              color: themeController.currentAppTheme.normalTextColor),
        ),
      ),
      body: Obx(() {
        final grouped = downloadController.groupedByVodName; // ✅ 从 controller 获取
        if (grouped.isEmpty) {
          return Center(child: Text("暂无下载"));
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView.builder(
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final vodName = grouped.keys.elementAt(index);
              final items = grouped[vodName]!;
              final firstItem = items.first;
              return InkWell(
                onTap: () {
                  Routes.goEpisodeListPage(vodName);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150.r,
                        height: 200.r,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: LoadingImage(pic: firstItem.vodPic),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: SizedBox(
                          height: 200.r,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8.h,),
                              Text(
                                vodName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Spacer(),
                              SizedBox(height: 8.h,),
                              Text(
                                '共 ${items.length} 集',
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(height: 8.h,),
                            ],
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
