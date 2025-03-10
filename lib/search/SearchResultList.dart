import 'package:flutter/material.dart';
import 'package:lemon_os/http/data/RealVideo.dart';
import 'package:lemon_os/mywidget/MyLoadingIndicator.dart';

import '../detail/DetailScreen.dart';
import '../util/LoadingImage.dart';

class SearchResultList extends StatefulWidget {
  final bool isLoading;
  final List<String> hasResultSite;
  final String selectSite;
  final ValueChanged<String> loadSearchResults;
  final RealResponseData selectResponseData;
  final bool hasSearch;

  const SearchResultList(
      {required this.isLoading,
      required this.hasResultSite,
      required this.selectSite,
      required this.loadSearchResults,
      required this.selectResponseData,
      required this.hasSearch});

  @override
  State<SearchResultList> createState() => _SearchResultListState();
}

class _SearchResultListState extends State<SearchResultList> {
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
          Expanded(
            flex: 6,
            child: widget.selectResponseData.videos.isEmpty
                ? Center(
                    child: Text(widget.hasSearch ? "没有找到相关视频" : ""),
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
        return GestureDetector(
          onTap: () {
            setState(() {
              widget.loadSearchResults(siteName);
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              siteName ?? "",
              style: TextStyle(
                  fontSize: 13.0,
                  color: (siteName == widget.selectSite)
                      ? Colors.red
                      : Colors.black,
                  fontWeight: (siteName == widget.selectSite)
                      ? FontWeight.bold
                      : FontWeight.normal),
            ),
          ),
        );
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(
                    vodId: video.vodId,
                    site: video.site,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                SizedBox(
                  height: 80,
                  width: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: LoadingImage(pic: video.vodPic),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.vodName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Row(
                        children: [
                          Text(
                            video.vodRemarks,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                              child: Text(
                            video.vodPubdate,
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          )),
                        ],
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        video.vodArea,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        video.typeName,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
