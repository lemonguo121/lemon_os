import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../http/data/RealVideo.dart';
import '../mywidget/MyLoadingIndicator.dart';
import '../util/widget/LoadingImage.dart';
import '../util/ThemeController.dart';

class SearchResultList extends StatefulWidget {
  final bool isLoading;
  final List<String> hasResultSite;
  final String selectSite;
  final ValueChanged<String> loadSearchResults;
  final ValueChanged<RealVideo> clickVideoItem;
  final RealResponseData selectResponseData;
  final bool hasSearch;

  const SearchResultList(
      {required this.isLoading,
      required this.hasResultSite,
      required this.selectSite,
      required this.loadSearchResults,
      required this.clickVideoItem,
      required this.selectResponseData,
      required this.hasSearch});

  @override
  State<SearchResultList> createState() => _SearchResultListState();
}

class _SearchResultListState extends State<SearchResultList> {
  final ThemeController themeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return _buildSearchResult();
  }

  Widget _buildSearchResult() {
    if (widget.isLoading) {
      return MyLoadingIndicator(isLoading: widget.isLoading);
    } else {
      return Expanded(
          child: Row(
        children: [
          Expanded(
            flex: 2,
            // 站点列表
            child: _buildSiteList(),
          ),
          SizedBox(
            width: 10.0,
          ),
          Expanded(
            flex: 6,
            child: widget.selectResponseData.videos.isEmpty
                ? Center(
                    child: Text(
                      widget.hasSearch ? "没有找到相关视频" : "",
                      style: TextStyle(
                          color: themeController
                              .currentAppTheme.selectedTextColor),
                    ),
                  )
                // 视频列表
                : _buildSearchVideoList(),
          ),
        ],
      ));
    }
  }

  Widget _buildSiteList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: widget.hasResultSite.length,
      itemBuilder: (context, index) {
        var siteName = widget.hasResultSite[index];
        return GestureDetector(onTap: () {
          setState(() {
            widget.loadSearchResults(siteName);
          });
        }, child: Obx(() {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              siteName ?? "",
              style: TextStyle(
                  fontSize: 13.0,
                  color: (siteName == widget.selectSite)
                      ? themeController.currentAppTheme.selectedTextColor
                      : themeController.currentAppTheme.normalTextColor,
                  fontWeight: (siteName == widget.selectSite)
                      ? FontWeight.bold
                      : FontWeight.normal),
            ),
          );
        }));
      },
    );
  }

  Widget _buildSearchVideoList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: widget.selectResponseData.videos.length,
      itemBuilder: (context, index) {
        var video = widget.selectResponseData.videos[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: InkWell(
            onTap: () {
              widget.clickVideoItem(video);
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 120,
                  width: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: LoadingImage(pic: video.vodPic),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4.0),
                      Text(
                        video.vodName,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: themeController
                                .currentAppTheme.titleColr),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        video.vodRemarks,
                        style: TextStyle(
                            fontSize: 12,
                            color: themeController
                                .currentAppTheme.contentColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        video.vodArea,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: themeController
                                .currentAppTheme.contentColor),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        video.typeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: themeController
                                .currentAppTheme.contentColor),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        video.vodPubdate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: themeController
                                .currentAppTheme.contentColor),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
