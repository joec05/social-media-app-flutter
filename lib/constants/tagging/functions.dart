import 'package:social_media_app/global_files.dart';

/// Returns true if the cursor position is set at the character '@'
/// Useful to detect when to display the bottom sheet to let the user search for other users to tag
bool isUserTagged(CustomTextFieldEditingController textController){
  final int cursorPosition = textController.selection.start;
  return cursorPosition > 0 ? textController.text.split('')[cursorPosition - 1] == '@' : false;
}