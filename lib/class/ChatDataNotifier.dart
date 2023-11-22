
import 'package:flutter/material.dart';
import 'package:social_media_app/class/ChatDataClass.dart';

class ChatDataNotifier{
  final String chatID;
  final ValueNotifier<ChatDataClass> notifier;

  ChatDataNotifier(this.chatID, this.notifier);
}