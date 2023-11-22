import 'package:flutter/material.dart';
import 'package:social_media_app/class/UserSocialClass.dart';

class UserSocialNotifier{
  final String userID;
  final ValueNotifier<UserSocialClass> notifier;

  UserSocialNotifier(this.userID, this.notifier);
}