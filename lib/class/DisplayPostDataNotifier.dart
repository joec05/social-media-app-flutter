import 'package:flutter/material.dart';
import 'package:social_media_app/class/DisplayPostDataClass.dart';


class DisplayPostDataNotifier{
  final String userID;
  final ValueNotifier<List<DisplayPostDataClass>> notifier;

  DisplayPostDataNotifier(this.userID, this.notifier);
}