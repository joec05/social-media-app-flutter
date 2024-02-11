import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class GroupMessageNotifier{
  final String messageID;
  final ValueNotifier<GroupMessageClass> notifier;

  GroupMessageNotifier(this.messageID, this.notifier);
}