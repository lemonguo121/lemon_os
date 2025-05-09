class LyricLine {
  final Duration time;
  final String text;
  double? height;
  LyricLine(this.time, this.text);

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      Duration(milliseconds: json['time'] ?? 0),
      json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.inMilliseconds,
      'text': text,
      'height':height
    };
  }
}