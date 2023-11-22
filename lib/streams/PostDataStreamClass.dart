import 'dart:async';
import '../class/DisplayPostDataClass.dart';

class PostDataStreamControllerClass{
  final DisplayPostDataClass postClass;
  final String uniqueID;

  PostDataStreamControllerClass(this.postClass, this.uniqueID);
}

class PostDataStreamClass {
  static final PostDataStreamClass _instance = PostDataStreamClass._internal();
  late StreamController<PostDataStreamControllerClass> _postDataStreamController;

  factory PostDataStreamClass(){
    return _instance;
  }

  PostDataStreamClass._internal() {
    _postDataStreamController = StreamController<PostDataStreamControllerClass>.broadcast();
  }

  Stream<PostDataStreamControllerClass> get postDataStream => _postDataStreamController.stream;

  void removeListener(){
    _postDataStreamController.stream.drain();
  }

  void emitData(PostDataStreamControllerClass data){
    if(!_postDataStreamController.isClosed){
      _postDataStreamController.add(data);
    }
  }

  void dispose(){
    _postDataStreamController.close();
  }

}