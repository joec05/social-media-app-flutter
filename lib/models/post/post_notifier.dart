import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class PostNotifier{
  final String postID;
  final ValueNotifier<PostClass> notifier;

  PostNotifier(this.postID, this.notifier);
}