import 'package:flutter/material.dart';
import 'package:lemon_os/mywidget/VodForamTag.dart';
import 'package:lemon_os/search/SearchScreen.dart';

import '../detail/DetailScreen.dart';
import '../http/data/RealVideo.dart';
import '../util/LoadingImage.dart';

class CategoryListItem extends StatefulWidget {
  final RealVideo realVideo;

  const CategoryListItem({super.key, required this.realVideo});

  @override
  State<CategoryListItem> createState() => _CategoryListItemState();
}

class _CategoryListItemState extends State<CategoryListItem> {
  @override
  Widget build(BuildContext context) {
    return _buildGridItem();
  }

  Widget _buildGridItem() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(
                vodId: widget.realVideo.vodId,
                site: widget.realVideo.site,
              ), // 动态传递vodId
            ));
      },
      onLongPress: () {
        setState(() {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      SearchScreen(query: widget.realVideo.vodName)));
        });
      },
      child: Stack(
        children: [
          // 封面图片
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LoadingImage(
              pic: widget.realVideo.vodPic,
            ),
          ),
          // 覆盖层显示文字
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
          VodForamTag(realVideo: widget.realVideo)
        ],
      ),
    );
  }
}
