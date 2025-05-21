import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:html/parser.dart';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class ReaderHomePage extends StatefulWidget {
  const ReaderHomePage({super.key});

  @override
  State<ReaderHomePage> createState() => _ReaderHomePageState();
}

class _ReaderHomePageState extends State<ReaderHomePage> {
  final indexUrl = 'https://www.biqukan.co';

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  void loadHomeData() async {
    final res = await http.get(Uri.parse('https://www.biqukan.co/book/9091/'));
    if (res.statusCode != 200) {
      print('目录页请求失败');
      return;
    }
    // final doc = parse(res.body);
    String decodedBody = utf8.decode(res.bodyBytes);
    final doc = parse(decodedBody);

    final novelTitle = doc
        .querySelector('col-md-3')
        ?.text
        .trim() ?? '未知小说';

    print('小说名称：$novelTitle');
    final chapterElements = doc.querySelectorAll('#list dd a');

    for (var i = 0; i < chapterElements.length && i < 10; i++) {
      final el = chapterElements[i];
      final chapterTitle = el.text.trim();
      final chapterUrl = 'https://www.biqukan.co${el.attributes['href']}';

      print('\n[$i] $chapterTitle');
      final content = await fetchChapter(chapterUrl);
      print(content.length > 100 ? content.substring(0, 100) + '...' : content);
    }
  }

  Future<String> fetchChapter(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      return '章节内容请求失败';
    }
    final doc = parse(res.body);
    final contentEl = doc.querySelector('#content');

    if (contentEl == null) return '章节内容为空';

    // 小说正文的换行用 <br> 或者 &nbsp;，处理成文本格式
    final rawText = contentEl.innerHtml
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'<.*?>'), '')
        .trim();

    return rawText;
  }

    @override
    Widget build(BuildContext context) {
      return const Placeholder();
    }
}
