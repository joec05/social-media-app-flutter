import 'package:flutter/material.dart';
import 'package:social_media_app/class/UserDataClass.dart';

class UserDataNotifier{
  final String userID;
  final ValueNotifier<UserDataClass> notifier;

  UserDataNotifier(this.userID, this.notifier);
}