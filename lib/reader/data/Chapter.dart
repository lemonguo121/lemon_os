import 'package:html/dom.dart' as dom;

// 章节类
class Chapter {
  final String title;
  final String url;

  Chapter({required this.title, required this.url});
}

// 卷类
class Volume {
  final String title;
  final List<Chapter> chapters;

  Volume({required this.title, required this.chapters});
}

List<Volume> parseVolumes(dom.Document doc) {
  final dirElement = doc.querySelector('dl#dir');
  if (dirElement == null) return [];

  List<Volume> volumes = [];
  String currentVolumeTitle = '';
  List<Chapter> currentChapters = [];

  for (var node in dirElement.nodes) {
    if (node is dom.Element) {
      if (node.localName == 'dt') {
        // 上一个卷收尾
        if (currentVolumeTitle.isNotEmpty) {
          volumes.add(Volume(title: currentVolumeTitle, chapters: currentChapters));
        }
        currentVolumeTitle = node.text.trim();
        currentChapters = [];
      } else if (node.localName == 'dd') {
        final a = node.querySelector('a');
        if (a != null) {
          final title = a.text.trim();
          final url = a.attributes['href'] ?? '';
          currentChapters.add(Chapter(title: title, url: url));
        }
      }
    }
  }
  // 最后一个卷加入
  if (currentVolumeTitle.isNotEmpty) {
    volumes.add(Volume(title: currentVolumeTitle, chapters: currentChapters));
  }
  return volumes;
}