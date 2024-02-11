import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class UserSocialNotifier{
  final String userID;
  final ValueNotifier<UserSocialClass> notifier;

  UserSocialNotifier(this.userID, this.notifier);
}