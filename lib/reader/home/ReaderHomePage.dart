import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;  // ✅ 使用别名 dom
import 'package:html_unescape/html_unescape.dart';

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
        .querySelector('.active')
        ?.text
        .trim() ?? '未知小说';
    print('小说名称：$novelTitle');

    final items = doc.querySelectorAll('.breadcrumb li');
    String novelType = '未知类型';
    if (items.length >= 2) {
      novelType = items[1].querySelector('a')?.text.trim() ?? '未知类型';
    }
    print('小说类型：$novelType');

    final imgElement = doc.querySelector('img.img-thumbnail');
    String imgSrc = imgElement?.attributes['src'] ?? '';
    if (imgSrc.isNotEmpty && imgSrc.startsWith('./')) {
      imgSrc = 'https://www.biqukan.co/' + imgSrc.substring(2); // 去掉 "./"
    }
    print('图片地址：$imgSrc');

    final chapterElements = doc.querySelectorAll('.panel-chapterlist dd a');

    for (var element in chapterElements) {
      final title = element.text.trim();
      final url = element.attributes['href'] ?? '';
      print('$title => https://www.biqukan.co$url');
    }
    var s = chapterElements[1].attributes['href'] ?? '';
    fetchChapterContent('https://www.biqukan.co$s');

  }

  Future<void> fetchChapterContent(String url) async {
    print('chaper content url = $url');
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      print('请求失败');
      return;
    }

    final document = parse(utf8.decode(res.bodyBytes));
    final title = document.querySelector('.readTitle')?.text.trim() ?? '未知标题';
    final contentElement = document.querySelector('#htmlContent');

    final unescape = HtmlUnescape();
    final buffer = StringBuffer();

    for (var node in contentElement?.nodes ?? []) {
      // 处理 script 标签中 base64 文本
      if (node.nodeType == Node.ELEMENT_NODE &&
          node is dom.Element &&
          node.localName == 'script') {
        final scriptText = node.text;
        final match = RegExp(r"qsbs\.bb\('(.+?)'\)").firstMatch(scriptText);
        if (match != null) {
          try {
            final base64Str = match.group(1)!;
            final decoded = utf8.decode(base64.decode(base64Str));
            final unescaped = unescape.convert(decoded);

            // 替换 <br> 为换行，&nbsp; 为空格，保留段首缩进
            final cleaned = unescaped
                .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
                .replaceAll('&nbsp;', ' ');

            buffer.writeln(cleaned);
          } catch (e) {
            print('解码失败: $e');
          }
        }
      }
    }

    print('\r\n章节标题：\r$title\n');
    print('\r\n章节正文：\r${buffer.toString()}');
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
