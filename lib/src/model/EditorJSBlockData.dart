import 'dart:developer';

import 'package:editorjs_flutter/src/model/EditorJSBlockFile.dart';

class EditorJSBlockData {
  final String? text;
  final int? level;
  final String? style;
  final List<String>? items;
  final EditorJSBlockFile? file;
  final String? caption;
  final bool? withBorder;
  final bool? stretched;
  final bool? withBackground;
  final String? buttonType;
  final String? buttonText;
  final String? buttonAction;
  final String? title;

  EditorJSBlockData({
    this.text,
    this.level,
    this.style,
    this.items,
    this.file,
    this.caption,
    this.withBorder,
    this.stretched,
    this.withBackground,
    this.buttonType,
    this.buttonText,
    this.buttonAction,
    this.title,
  });

  factory EditorJSBlockData.fromJson(Map<String, dynamic> parsedJson) {
    var list = parsedJson['items'] as List?;
    final List<String> itemsList = <String>[];

    if (list != null) {
      list.forEach((element) {
        itemsList.add(element);
      });
    }

    return EditorJSBlockData(
      text: parsedJson['text'] is String ? parsedJson['text'] : null,
      level: parsedJson['level'] is int ? parsedJson['level'] : null,
      style: parsedJson['style'] is String ? parsedJson['style'] : null,
      items: itemsList.isNotEmpty ? itemsList : null,
      file: (parsedJson['file'] is Map<String, dynamic>)
          ? EditorJSBlockFile.fromJson(parsedJson['file'] as Map<String, dynamic>)
          : null,
      caption: parsedJson['caption'] is String ? parsedJson['caption'] : null,
      withBorder: parsedJson['withBorder'] is bool ? parsedJson['withBorder'] : null,
      withBackground: parsedJson['withBackground'] is bool ? parsedJson['withBackground'] : null,
      buttonType: parsedJson['buttonType'] is String ? parsedJson['buttonType'] : null,
      buttonText: parsedJson['buttonText'] is String ? parsedJson['buttonText'] : null,
      buttonAction: parsedJson['buttonAction'] is String ? parsedJson['buttonAction'] : null,
      title: parsedJson['title'] is String ? parsedJson['title'] : null,
    );
  }
}
