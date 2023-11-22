import 'dart:async';

class RequestsToDataStreamControllerClass{
  final String userID;
  final String uniqueID;

  RequestsToDataStreamControllerClass(this.userID, this.uniqueID);
}

class RequestsToDataStreamClass {
  static final RequestsToDataStreamClass _instance = RequestsToDataStreamClass._internal();
  late StreamController<RequestsToDataStreamControllerClass> _requestsToDataStreamController;

  factory RequestsToDataStreamClass(){
    return _instance;
  }

  RequestsToDataStreamClass._internal() {
    _requestsToDataStreamController = StreamController<RequestsToDataStreamControllerClass>.broadcast();
  }

  Stream<RequestsToDataStreamControllerClass> get requestsToDataStream => _requestsToDataStreamController.stream;

  void removeListener(){
    _requestsToDataStreamController.stream.drain();
  }

  void emitData(RequestsToDataStreamControllerClass data){
    if(!_requestsToDataStreamController.isClosed){
      _requestsToDataStreamController.add(data);
    }
  }

  void dispose(){
    _requestsToDataStreamController.close();
  }

}