import 'package:flutter/material.dart';

import '../util/SPManager.dart';

class SearchHistoryList extends StatefulWidget {
  final List<String> searchHistory;
  final ValueChanged<String> changeEditingController;
  final ValueChanged<int> deleteSearchHistory;
  final VoidCallback clearSearchHistory;

  const SearchHistoryList(
      {super.key,
      required this.searchHistory,
      required this.changeEditingController,
      required this.deleteSearchHistory,
      required this.clearSearchHistory});

  @override
  State<SearchHistoryList> createState() => _SearchHistoryListState();
}

class _SearchHistoryListState extends State<SearchHistoryList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _buildSearchHistory();
  }

  Widget _buildSearchHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '搜索历史',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: widget.clearSearchHistory,
              child: Text("清空"),
            ),
          ],
        ),
        Wrap(
          spacing: 2.0, // 每个条目之间的水平间距
          runSpacing: 2.0, // 每行之间的垂直间距
          children: widget.searchHistory
              .take(12) // 限制最多显示12条记录
              .map((history) {
            return GestureDetector(
                onTap: () {
                  setState(() {
                    widget.changeEditingController(history);
                  });
                },
                onLongPress: () => widget
                    .deleteSearchHistory(widget.searchHistory.indexOf(history)),
                child: SizedBox(
                  height: 30,
                  child: Chip(
                    label: Text(history, style: TextStyle(fontSize: 11.0)),
                    deleteIcon: Icon(Icons.close, size: 14.0),
                    onDeleted: () => widget.deleteSearchHistory(
                        widget.searchHistory.indexOf(history)),
                  ),
                ));
          }).toList(),
        ),
      ],
    );
  }
}
