import 'dart:async';
import '../class/DisplayCommentDataClass.dart';

class CommentDataStreamControllerClass{
  final DisplayCommentDataClass commentClass;
  final String uniqueID;

  CommentDataStreamControllerClass(this.commentClass, this.uniqueID);
}

class CommentDataStreamClass {
  static final CommentDataStreamClass _instance = CommentDataStreamClass._internal();
  late StreamController<CommentDataStreamControllerClass> _commentDataStreamController;

  factory CommentDataStreamClass(){
    return _instance;
  }

  CommentDataStreamClass._internal() {
    _commentDataStreamController = StreamController<CommentDataStreamControllerClass>.broadcast();
  }

  Stream<CommentDataStreamControllerClass> get commentDataStream => _commentDataStreamController.stream;

  void removeListener(){
    _commentDataStreamController.stream.drain();
  }

  void emitData(CommentDataStreamControllerClass data){
    print('comment stream emitted');
    if(!_commentDataStreamController.isClosed){
    print('comment stream isnt closed');
      _commentDataStreamController.add(data);
    }
  }

  void dispose(){
    _commentDataStreamController.close();
  }

}