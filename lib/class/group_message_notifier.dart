import 'package:flutter/material.dart';
import 'group_message_class.dart';

class GroupMessageNotifier{
  final String messageID;
  final ValueNotifier<GroupMessageClass> notifier;

  GroupMessageNotifier(this.messageID, this.notifier);
}