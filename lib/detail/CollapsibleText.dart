import 'package:flutter/material.dart';

class CollapsibleText extends StatefulWidget {
  final String text;
  final int maxLines; // 折叠时的最大行数
  final TextStyle? style;

  const CollapsibleText({
    super.key,
    required this.text,
    this.maxLines = 3, // 默认折叠为 3 行
    this.style,
  });

  @override
  _CollapsibleTextState createState() => _CollapsibleTextState();
}

class _CollapsibleTextState extends State<CollapsibleText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: widget.style,
          maxLines: _isExpanded ? null : widget.maxLines, // 根据状态显示行数
          overflow: TextOverflow.ellipsis, // 超出内容显示省略号
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(
            _isExpanded ? "展开" : "收起",
            style: const TextStyle(color: Colors.blue, fontSize: 12.0),
          ),
        ),
      ],
    );
  }
}
