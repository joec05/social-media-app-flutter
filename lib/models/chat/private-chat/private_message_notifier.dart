import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class PrivateMessageNotifier{
  final String messageID;
  final ValueNotifier<PrivateMessageClass> notifier;

  PrivateMessageNotifier(this.messageID, this.notifier);
}