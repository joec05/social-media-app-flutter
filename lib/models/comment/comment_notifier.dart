import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class CommentNotifier{
  final String commentID;
  final ValueNotifier<CommentClass> notifier;

  CommentNotifier(this.commentID, this.notifier);
}