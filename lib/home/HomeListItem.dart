import 'package:flutter/material.dart';
import '../http/data/RealVideo.dart';
import '../util/LoadingImage.dart';

import '../detail/DetailScreen.dart';

class HomeListItem extends StatefulWidget {
  final RealVideo video;

  const HomeListItem({super.key, required this.video});

  @override
  State<HomeListItem> createState() => _HomeListItemState();
}

class _HomeListItemState extends State<HomeListItem> {
  @override
  Widget build(BuildContext context) {
    return _buildItem(widget.video);
  }

  Widget _buildItem(RealVideo video) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetailScreen(vodId: video.vodId,subscription:video.subscriptionDomain), // 动态传递vodId
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120.0, // 图片高度
              width: 90.0, // 图片宽度
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LoadingImage(pic: video.vodPic,),
              ),
            ),
            const SizedBox(width: 10.0), // 图片和文字的间距
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2,),
                Text(
                  video.vodName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5,),
                Row(
                  children: [
                    const Text(
                      "更新:",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Flexible(
                        child: Text(
                      video.vodPubdate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      "分类:",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Flexible(
                        child: Text(
                      video.vodArea,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )),
                    const SizedBox(
                      width: 4.0,
                    ),
                    Flexible(
                        child: Text(
                      video.typeName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ))
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      "演员:",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Flexible(
                        child: Text(
                      video.vodActor,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "简介:",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Flexible(
                        child: Text(
                      video.vodBlurb,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ))
                  ],
                )
              ],
            )),
          ],
        ),
      ),
    );
  }
}
