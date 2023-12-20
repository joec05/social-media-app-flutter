import 'dart:async';

class BookmarkDataStreamControllerClass{
  final dynamic postClass;
  final String uniqueID;

  BookmarkDataStreamControllerClass(this.postClass, this.uniqueID);
}

class BookmarkDataStreamClass {
  static final BookmarkDataStreamClass _instance = BookmarkDataStreamClass._internal();
  late StreamController<BookmarkDataStreamControllerClass> _bookmarkDataStreamController;

  factory BookmarkDataStreamClass(){
    return _instance;
  }

  BookmarkDataStreamClass._internal() {
    _bookmarkDataStreamController = StreamController<BookmarkDataStreamControllerClass>.broadcast();
  }

  Stream<BookmarkDataStreamControllerClass> get bookmarkDataStream => _bookmarkDataStreamController.stream;


  void removeListener(){
    _bookmarkDataStreamController.stream.drain();
  }

  void emitData(BookmarkDataStreamControllerClass data){
    if(!_bookmarkDataStreamController.isClosed){
      _bookmarkDataStreamController.add(data);
    }
  }

  void dispose(){
    _bookmarkDataStreamController.close();
  }

}