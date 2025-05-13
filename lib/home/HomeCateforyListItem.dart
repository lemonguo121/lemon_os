import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../detail/DetailScreen.dart';
import '../http/data/RealVideo.dart';
import '../mywidget/VodForamTag.dart';
import '../routes/routes.dart';
import '../search/SearchScreen.dart';
import '../util/CommonUtil.dart';
import '../util/widget/LoadingImage.dart';

class Homecateforylistitem extends StatefulWidget {
  final RealVideo realVideo;

  const Homecateforylistitem({super.key, required this.realVideo});

  @override
  State<Homecateforylistitem> createState() => _HomecateforylistitemState();
}

class _HomecateforylistitemState extends State<Homecateforylistitem> {
  @override
  Widget build(BuildContext context) {
    return _buildItem(widget.realVideo);
  }

  Widget _buildItem(RealVideo video) {
    var isVertical = CommonUtil.isVertical(context);
    var itemCount = isVertical ? 3.2 : 6.5;
    var screenWidth = CommonUtil.getScreenWidth(context);
    var itemMargin = 8.0;
    var itemWidth = (screenWidth - ((itemCount + 1) * itemMargin)) / itemCount;
    var itemHeight = itemWidth / 3 * 4;
    return Container(
        height: itemHeight, // 图片高度
        width: itemWidth, // 图片宽度
        margin: EdgeInsets.only(right: itemMargin, bottom: 10.0),
        child: GestureDetector(
          onTap: () {
            Routes.goDetailPage('${video.vodId}', video.site,-1);
          },
          onLongPress: () {
            Routes.goSearchPage(video.vodName);
          },
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: LoadingImage(
                  pic: video.vodPic,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter, // 渐变起点（顶部）
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0), // 顶部完全透明
                            Colors.black.withOpacity(0.9), // 底部半透明黑色
                          ]),
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0))),
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.realVideo.vodRemarks,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.realVideo.vodArea,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.realVideo.vodYear,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.realVideo.vodName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // 右上角的红色矩形角标
              VodForamTag(realVideo: widget.realVideo),
            ],
          ),
        ));
  }
}
