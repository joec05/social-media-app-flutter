import 'package:flutter/material.dart';
import 'private_message_class.dart';

class PrivateMessageNotifier{
  final String messageID;
  final ValueNotifier<PrivateMessageClass> notifier;

  PrivateMessageNotifier(this.messageID, this.notifier);
}