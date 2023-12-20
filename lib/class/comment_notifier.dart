import 'package:flutter/material.dart';

import 'comment_class.dart';

class CommentNotifier{
  final String commentID;
  final ValueNotifier<CommentClass> notifier;

  CommentNotifier(this.commentID, this.notifier);
}