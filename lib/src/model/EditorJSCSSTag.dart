class EditorJSCSSTag {
  final String? tag;
  final String? backgroundColor;
  final String? fontFamily;
  final String? lineHeight;
  final String? fontSize;
  final String? color;
  final double? padding;
  final int? fontWeight;

  EditorJSCSSTag({this.tag, this.backgroundColor, this.color, this.padding, this.fontFamily, this.lineHeight, this.fontSize, this.fontWeight});

  factory EditorJSCSSTag.fromJson(Map<String, dynamic> parsedJson) {
    return EditorJSCSSTag(
      tag: parsedJson['tag'],
      backgroundColor: parsedJson['backgroundColor'],
      color: parsedJson['color'],
      padding: parsedJson['padding'],
      fontFamily: parsedJson['font-family'],
      lineHeight: parsedJson['line-height'],
      fontSize: parsedJson['font-size'],
      fontWeight: parsedJson['font-weight'],

    );
  }
}
