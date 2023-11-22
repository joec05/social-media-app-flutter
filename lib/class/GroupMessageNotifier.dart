
import 'package:flutter/material.dart';
import 'GroupMessageClass.dart';

class GroupMessageNotifier{
  final String messageID;
  final ValueNotifier<GroupMessageClass> notifier;

  GroupMessageNotifier(this.messageID, this.notifier);
}