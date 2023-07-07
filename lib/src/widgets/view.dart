import 'dart:convert';
import 'dart:ffi';

import 'package:editorjs_flutter/OverlayUIComponents/AudioPlayer/audio_player.dart';
import 'package:editorjs_flutter/src/model/EditorJSBlockData.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:editorjs_flutter/src/model/EditorJSData.dart';
import 'package:editorjs_flutter/src/model/EditorJSViewStyles.dart';
import 'package:editorjs_flutter/src/model/EditorJSCSSTag.dart';
import 'package:flutter_html/flutter_html.dart';

import 'dart:developer';

import 'package:editorjs_flutter/OverlayUIComponents/orange_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;
import 'package:url_launcher/url_launcher.dart';

import '../../OverlayUIComponents/VideoPlayer/video_player.dart';

typedef EditorJSButtonCallback = void Function(
    EditorJSBlockData? buttonAction, BuildContext context);

class EditorJSView extends StatefulWidget {
  // isPreview is used to conditionally add padding at the bottom of the EditorJSView column (we don't want it in preview mode)
  final bool isPreview;
  final EditorJSButtonCallback? onButtonAction;
  final String? editorJSData;
  final String? styles;

  const EditorJSView(
      {Key? key,
      required this.isPreview,
      this.editorJSData,
      this.styles,
      this.onButtonAction})
      : super(key: key);

  @override
  EditorJSViewState createState() => EditorJSViewState();
}

class EditorJSViewState extends State<EditorJSView> {
  String? data;
  late EditorJSData dataObject;
  late EditorJSViewStyles styles;
  final List<Widget> items = <Widget>[];
  late Map<String, Style> customStyleMap;
  late Map<String, TextStyle> customTextStyleMap;

  AudioPlayer? _currentlyPlayingAudioPlayer;
  bool _isSomethingPlaying = false;

  /// If an audio player is already playing, and you play a second one, the first one gets paused
  void pauseOtherAudioPlayers(AudioPlayer audioPlayer) {
    //If something is already playing, pause that so we can play this instead, and update the currently playing reference
    if (_isSomethingPlaying) {
      _currentlyPlayingAudioPlayer!.pause();
      _currentlyPlayingAudioPlayer = audioPlayer;
    }
    //If nothing is currently playing, do nothing, but update the currently playing reference
    else {
      _currentlyPlayingAudioPlayer = audioPlayer;
      _isSomethingPlaying = true;
    }
  }

  @override
  void initState() {
    super.initState();

    setState(
      () {
        dataObject = EditorJSData.fromJson(jsonDecode(widget.editorJSData!));
        styles = EditorJSViewStyles.fromJson(jsonDecode(widget.styles!));

        customStyleMap = generateStylemap(styles.cssTags!);
        customTextStyleMap = generateTextStylemap(styles.cssTags!);

        // log("STYLES: " + customStyleMap.toString());
        // log("TEXTSTYLES: " + customTextStyleMap.toString());

        dataObject.blocks!.forEach(
          (element) {
            double levelFontSize = 16;
            switch (element.data!.level) {
              case 1:
                levelFontSize = 32;
                break;
              case 2:
                levelFontSize = 24;
                break;
              case 3:
                levelFontSize = 16;
                break;
              case 4:
                levelFontSize = 12;
                break;
              case 5:
                levelFontSize = 10;
                break;
              case 6:
                levelFontSize = 8;
                break;
            }

            switch (element.type) {
              case "header":
                if (element.data != null) {
                  if (element.data!.text != null) {
                    if (element.data!.text!.isNotEmpty) {
                      if (element.data!.level != null) {
                        if (element.data!.level! >= 1 &&
                            element.data!.level! <= 6) {
                          items.add(Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              filterText(element.data!.text!),
                              style:
                                  customTextStyleMap["h${element.data!.level}"],
                            ),
                          ));
                        }
                      }
                    }
                  }
                }
                break;
              case "paragraph":
                items.add(Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        // Note: Styles for TextSpans must be explicitly defined.
                        // Child text spans will inherit styles from parent
                        style: customTextStyleMap["p"],
                        children:
                            processHtmlTags(filterText(element.data!.text!)),
                      ),
                    )));
                break;
              case "list":
                String bullet = "\u2022 ";
                String? style = element.data!.style;
                int counter = 1;
                String listString = "";
                element.data!.items!.forEach((element) {
                  if (style == 'ordered') {
                    listString += "$counter. $element\n";
                  } else {
                    listString += "$bullet $element\n";
                  }
                  counter++;
                });
                items.add(Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      filterText(listString),
                      style: style == 'ordered'
                          ? customTextStyleMap["ol"]
                          : customTextStyleMap["ul"],
                    )));
                break;
              case "delimiter":
                items.add(Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [Expanded(child: Divider(color: Colors.grey))]));
                break;
              case "image":
                items.add(Image.network(element.data!.file!.url!));
                break;
              case "button":
                if (element.data != null) {
                  if (element.data!.buttonText != null) {
                    if (element.data!.buttonAction != null) {
                      if (element.data!.buttonType != null) {
                        items.add(
                          EditorJSOrangeButton(
                            text: element.data!.buttonText!,
                            onPressed: () {
                              log("buttonPressed!!");
                              widget.onButtonAction!(element.data, context);
                            },
                            buttonType: element.data!.buttonType!,
                          ),
                        );
                      }
                    }
                  }
                }
                break;
              case "audio":
                if (element.data != null) {
                  if (element.data!.file != null) {
                    if (element.data!.file!.url != null) {
                      if (element.data!.title != null) {
                        items.add(
                          OverlayAudioPlayer(
                            audioFirebaseStoragePath: element.data!.file!.url!,
                            audioTitle: element.data!.title!,
                            pauseOtherAudioPlayers: pauseOtherAudioPlayers,
                          ),
                        );
                      }
                    }
                  }
                }
                break;
              case "video":
                if (element.data != null) {
                  if (element.data!.file != null) {
                    if (element.data!.file!.url != null) {
                      if (element.data!.title != null) {
                        items.add(
                          OverlayVideoPlayer(
                            videoFirebaseStoragePath: element.data!.file!.url!,
                            videoTitle: element.data!.title!,
                          ),
                        );
                      }
                    }
                  }
                }
                break;
            }
            if (!widget.isPreview) {
              items.add(const SizedBox(height: 10));
            }
          },
        );
      },
    );
  }

  String filterText(String input) {
    String filteredString = input;
    filteredString = filteredString.replaceAll("&nbsp;", " ");
    return filteredString;
  }

  Map<String, Style> generateStylemap(List<EditorJSCSSTag> styles) {
    Map<String, Style> map = <String, Style>{};

    styles.forEach(
      (element) {
        map.putIfAbsent(
            element.tag.toString(),
            () => Style(
                backgroundColor: (element.backgroundColor != null)
                    ? getColor(element.backgroundColor!)
                    : null,
                color:
                    (element.color != null) ? getColor(element.color!) : null,
                padding: (element.padding != null)
                    ? EdgeInsets.all(element.padding!)
                    : null));
      },
    );

    return map;
  }

  Map<String, TextStyle> generateTextStylemap(List<EditorJSCSSTag> styles) {
    Map<String, TextStyle> map = <String, TextStyle>{};
    styles.forEach(
      (element) {
        map.putIfAbsent(
          element.tag.toString(),
          () => GoogleFonts.getFont(
            element.fontFamily ?? "Rubik",
            backgroundColor: (element.backgroundColor != null)
                ? getColor(element.backgroundColor!)
                : null,
            color: (element.color != null) ? getColor(element.color!) : null,
            fontSize: convertFontSize(element.fontSize),
            fontWeight: convertFontWeight(element.fontWeight),
          ),
        );
      },
    );

    return map;
  }

  double convertFontSize(String? fontSize) {
    if (fontSize == null) return 14;
    if (fontSize.contains("px")) {
      String sizeString = fontSize.substring(0, fontSize.length - 2);
      return double.parse(sizeString);
    } else if (fontSize.contains("em")) {
      String sizeString = fontSize.substring(0, fontSize.length - 2);
      return double.parse(sizeString) * 16;
    } else if (fontSize.contains("%")) {
      String sizeString = fontSize.substring(0, fontSize.length - 1);
      return double.parse(sizeString) * 16;
    }
    return 14;
  }

  FontWeight convertFontWeight(int? fontWeight) {
    if (fontWeight == 100) return FontWeight.w100;
    if (fontWeight == 200) return FontWeight.w200;
    if (fontWeight == 300) return FontWeight.w300;
    if (fontWeight == 400) return FontWeight.w400;
    if (fontWeight == 500) return FontWeight.w500;
    if (fontWeight == 600) return FontWeight.w600;
    if (fontWeight == 700) return FontWeight.w700;
    if (fontWeight == 800) return FontWeight.w800;
    if (fontWeight == 900) return FontWeight.w900;
    return FontWeight.w400;
  }

  List<TextSpan> processHtmlTags(String htmlString) {
    List<TextSpan> textSpans = [];

    dom.Document document = htmlParser.parse(htmlString);

    void parseNode(dom.Node node, TextStyle style) {
      if (node is dom.Text) {
        textSpans.add(TextSpan(text: node.text, style: style));
      } else if (node is dom.Element) {
        TextStyle newStyle = style;

        if (node.localName == 'b') {
          newStyle = newStyle.copyWith(fontWeight: FontWeight.bold);
        } else if (node.localName == 'i') {
          newStyle = newStyle.copyWith(fontStyle: FontStyle.italic);
        } else if (node.localName == 'a') {
          String? href = node.attributes['href'];
          if (href != null && href.isNotEmpty) {
            textSpans.add(
              TextSpan(
                text: node.text,
                style: newStyle.copyWith(
                  decoration: TextDecoration.underline,
                  color: Colors.blue, // Customize the link color here
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    log("HIT URL");
                    launchUrl(Uri.parse(href),
                        mode: LaunchMode.externalApplication);
                  },
              ),
            );
          } else {
            newStyle = newStyle.copyWith(
              decoration: TextDecoration.underline,
              color: Colors.blue, // Customize the link color here
            );
          }
        }

        for (var childNode in node.nodes) {
          parseNode(childNode, newStyle);
        }
      }
    }

    for (var node in document.body!.nodes) {
      parseNode(node, TextStyle());
    }

    return textSpans;
  }

  Color getColor(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('$hexCode', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: items);
  }
}
