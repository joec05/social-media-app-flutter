import 'package:flutter/cupertino.dart';
import '../class/CommentNotifier.dart';
import '../class/DisplayPostDataNotifier.dart';
import '../class/PostNotifier.dart';
import '../class/UserDataNotifier.dart';
import '../class/UserSocialNotifier.dart';

class CurrentID{
  final String payload;
  CurrentID(this.payload);
}

class SocketID{
  final String payload;
  SocketID(this.payload);
}

class UsersDatasNotifiers{
  final ValueNotifier<Map<String, UserDataNotifier>> payload;
  UsersDatasNotifiers(this.payload);
}

class UsersSocialsNotifiers{
  final ValueNotifier<Map<String, UserSocialNotifier>> payload;
  UsersSocialsNotifiers(this.payload);
}

class PostsNotifiers{
  final ValueNotifier<Map<String, Map<String, PostNotifier>>> payload;
  PostsNotifiers(this.payload);
}

class CommentsNotifiers{
  final ValueNotifier<Map<String, Map<String, CommentNotifier>>> payload;
  CommentsNotifiers(this.payload);
}

class UsersProfilePostsNotifiers{
  final ValueNotifier<Map<String, DisplayPostDataNotifier>> payload;
  UsersProfilePostsNotifiers(this.payload);
}