
import 'package:flutter/material.dart';
import 'PrivateMessageClass.dart';

class PrivateMessageNotifier{
  final String messageID;
  final ValueNotifier<PrivateMessageClass> notifier;

  PrivateMessageNotifier(this.messageID, this.notifier);
}