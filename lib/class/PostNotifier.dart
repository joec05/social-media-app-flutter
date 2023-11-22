import 'package:flutter/material.dart';

import 'PostClass.dart';

class PostNotifier{
  final String postID;
  final ValueNotifier<PostClass> notifier;

  PostNotifier(this.postID, this.notifier);
}