import 'package:characters/characters.dart';

extension StringEllipsis on String {
  static String convertToEllipsis(str) {
    return Characters(str).replaceAll(Characters(''), Characters('\u{200B}')).toString();
  }
}