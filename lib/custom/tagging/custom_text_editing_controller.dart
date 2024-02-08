import 'package:flutter/material.dart';
import 'package:social_media_app/constants/global_functions.dart';

class CustomTextFieldEditingController extends TextEditingController {

  CustomTextFieldEditingController({String? text});

  @override
  set text(String newText) {
    value = value.copyWith(
      text: newText,
      selection: const TextSelection.collapsed(offset: -1),
      composing: TextRange.empty,
    );
  }


  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
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
        children.add(TextSpan(text: m[0], style: textDisplayRegexStyle[selectedRegex]));
        return m[0].toString();
      },
    );
    return TextSpan(style: style, children: children);
  }
}