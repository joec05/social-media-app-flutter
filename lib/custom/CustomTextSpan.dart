import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/ProfilePageWithUsername.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/custom/CustomWebPageViewer.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import '../Searched.dart';

RegExp textDisplayUserTagRegex = RegExp(r"\B@[a-zA-Z0-9_]{1," + profileInputMaxLimit['username'].toString()+ r"}(?<=\w)");

RegExp atTypedDisplayUserListRegex = RegExp("(?<![a-zA-Z0-9_])@");

RegExp textDisplayHashtagRegex = RegExp(r"\B#[a-zA-Z0-9_]{1," + hashtagTextInputMaxLimit.toString() + r"}(?<=\w)");

RegExp atTypedDisplayHashtagListRegex = RegExp("(?<![a-zA-Z0-9_])#");

RegExp isLinkRegex = RegExp(r'^(?:(?:https?|ftp):\/\/)?[\w-]+(\.[\w-]+)+[\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-]$');
RegExp isLinkRegexTyped = RegExp(r'(?:^|\s)(?:(?:https?|ftp):\/\/)?[\w-]+(\.[\w-]+)+[\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-](?:$|\s)');

Map<RegExp, TextStyle> textDisplayRegexStyle = {
  textDisplayUserTagRegex: const TextStyle(color: Color.fromARGB(255, 16, 61, 100), fontWeight: FontWeight.w600),
  textDisplayHashtagRegex: const TextStyle(color: Color.fromARGB(255, 40, 81, 117), fontWeight: FontWeight.w600),
  isLinkRegexTyped: const TextStyle(color: Color.fromARGB(255, 40, 81, 117), fontWeight: FontWeight.w600)
};


List<TextSpan> generateTextSpanTag(text, tagsPressable, context){
  List<TextSpan> children = [];
  RegExp allRegex = RegExp(textDisplayRegexStyle.keys.map((e) => e.pattern).join('|'));

  text.splitMapJoin(
    allRegex,
    onNonMatch: (String span) {
      children.add(TextSpan(text: span));
      return span.toString();
    },
    onMatch: (Match m) {
      final RegExp selectedRegex = textDisplayRegexStyle.entries.firstWhere((element) {
        return element.key.allMatches(m[0]!).isNotEmpty;
      }).key;
      children.add(
        TextSpan(
          text: m[0], style: textDisplayRegexStyle[selectedRegex],
          recognizer: TapGestureRecognizer()..onTap = tagsPressable ? () {
            String str = m[0]!.trim().replaceAll('\n', '');
            if(str.isNotEmpty){
              if(str[0] == '@'){
                runDelay(() => Navigator.push(
                  context,
                  SliderRightToLeftRoute(
                    page: ProfilePageWithUsernameWidget(username: str.substring(1))
                  )
                ), navigatorDelayTime);
              }else if(str[0] == '#'){
                runDelay(() => Navigator.push(
                  context,
                  SliderRightToLeftRoute(
                    page: SearchedWidget(searchedText: str)
                  )
                ), navigatorDelayTime);
              }else{
                runDelay(() => Navigator.push(
                  context,
                  SliderRightToLeftRoute(
                    page: CustomWebPageViewer(url: str),
                  ),
                ), navigatorDelayTime);
              }
            }
          } : null,
        )
      );
      return m[0].toString();
    },
  );
  
  return children;
}

class DisplayTextComponent extends StatelessWidget {
  final String text;
  final bool tagsPressable;
  final TextOverflow overflow;
  final int maxLines;
  final TextStyle style;
  final TextAlign alignment;
  final BuildContext context;

  const DisplayTextComponent({Key? key, required this.text, required this.tagsPressable, required this.overflow, required this.maxLines, required this.style, required this.alignment, required this.context}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    List<TextSpan> children = generateTextSpanTag(text, tagsPressable, context);
    
    return RichText(
      text: TextSpan(children: children, style: style),
      overflow: overflow, maxLines: maxLines, textAlign: alignment,
    );
  }
}