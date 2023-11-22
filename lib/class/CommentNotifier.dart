import 'package:flutter/material.dart';

import 'CommentClass.dart';

class CommentNotifier{
  final String commentID;
  final ValueNotifier<CommentClass> notifier;

  CommentNotifier(this.commentID, this.notifier);
}