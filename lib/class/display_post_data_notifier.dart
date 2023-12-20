import 'package:flutter/material.dart';
import 'package:social_media_app/class/display_post_data_class.dart';


class DisplayPostDataNotifier{
  final String userID;
  final ValueNotifier<List<DisplayPostDataClass>> notifier;

  DisplayPostDataNotifier(this.userID, this.notifier);
}