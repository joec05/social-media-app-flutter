import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class UserDataNotifier{
  final String userID;
  final ValueNotifier<UserDataClass> notifier;

  UserDataNotifier(this.userID, this.notifier);
}