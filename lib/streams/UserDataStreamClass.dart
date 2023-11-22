import 'dart:async';

enum UserDataStreamsUpdateType{
  addFollowers, addFollowing, removeFollowers, removeFollowing, 
  addPostLikes, addPostBookmarks, removePostLikes, removePostBookmarks,
  addCommentLikes, addCommentBookmarks, removeCommentLikes, removeCommentBookmarks
}

class UserDataStreamControllerClass{
  final String userID;
  final String uniqueID;
  final UserDataStreamsUpdateType actionType;

  UserDataStreamControllerClass(this.userID, this.uniqueID, this.actionType);
}

class UserDataStreamClass {
  static final UserDataStreamClass _instance = UserDataStreamClass._internal();
  late StreamController<UserDataStreamControllerClass> _userDataStreamController;

  factory UserDataStreamClass(){
    return _instance;
  }

  UserDataStreamClass._internal() {
    _userDataStreamController = StreamController<UserDataStreamControllerClass>.broadcast();
  }

  Stream<UserDataStreamControllerClass> get userDataStream => _userDataStreamController.stream;

  void removeListener(){
    _userDataStreamController.stream.drain();
  }

  void emitData(UserDataStreamControllerClass data){
    if(!_userDataStreamController.isClosed){
      _userDataStreamController.add(data);
    }
  }

  void dispose(){
    _userDataStreamController.close();
  }

}