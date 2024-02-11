import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ChatDataNotifier{
  final String chatID;
  final ValueNotifier<ChatDataClass> notifier;

  ChatDataNotifier(this.chatID, this.notifier);
}