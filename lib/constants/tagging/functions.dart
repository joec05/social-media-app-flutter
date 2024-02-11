import 'package:social_media_app/global_files.dart';

bool isUserTagged(CustomTextFieldEditingController textController){
  final int cursorPosition = textController.selection.start;
  return cursorPosition > 0 ? textController.text.split('')[cursorPosition - 1] == '@' : false;
}

bool isTextHashtagged(CustomTextFieldEditingController textController){
  final int cursorPosition = textController.selection.start;
  return cursorPosition > 0 ? textController.text.split('')[cursorPosition - 1] == '#' : false;
}