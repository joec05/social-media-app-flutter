import 'dart:async';

class RequestsFromDataStreamControllerClass{
  final String userID;
  final String uniqueID;

  RequestsFromDataStreamControllerClass(this.userID, this.uniqueID);
}

class RequestsFromDataStreamClass {
  static final RequestsFromDataStreamClass _instance = RequestsFromDataStreamClass._internal();
  late StreamController<RequestsFromDataStreamControllerClass> _requestsFromDataStreamController;

  factory RequestsFromDataStreamClass(){
    return _instance;
  }

  RequestsFromDataStreamClass._internal() {
    _requestsFromDataStreamController = StreamController<RequestsFromDataStreamControllerClass>.broadcast();
  }

  Stream<RequestsFromDataStreamControllerClass> get requestsFromDataStream => _requestsFromDataStreamController.stream;

  void removeListener(){
    _requestsFromDataStreamController.stream.drain();
  }

  void emitData(RequestsFromDataStreamControllerClass data){
    if(!_requestsFromDataStreamController.isClosed){
      _requestsFromDataStreamController.add(data);
    }
  }

  void dispose(){
    _requestsFromDataStreamController.close();
  }

}