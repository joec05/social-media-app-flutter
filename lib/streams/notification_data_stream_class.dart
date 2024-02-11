import 'dart:async';

import 'package:social_media_app/models/notification/notification_class.dart';

class NotificationDataStreamControllerClass{
  final NotificationClass notificationClass;
  final String uniqueID;

  NotificationDataStreamControllerClass(this.notificationClass, this.uniqueID);
}

class NotificationDataStreamClass {
  static final NotificationDataStreamClass _instance = NotificationDataStreamClass._internal();
  late StreamController<NotificationDataStreamControllerClass> _notificationDataStreamController;

  factory NotificationDataStreamClass(){
    return _instance;
  }

  NotificationDataStreamClass._internal() {
    _notificationDataStreamController = StreamController<NotificationDataStreamControllerClass>.broadcast();
  }

  Stream<NotificationDataStreamControllerClass> get notificationDataStream => _notificationDataStreamController.stream;

  void removeListener(){
    _notificationDataStreamController.stream.drain();
  }

  void emitData(NotificationDataStreamControllerClass data){
    if(!_notificationDataStreamController.isClosed){
      _notificationDataStreamController.add(data);
    }
  }

  void dispose(){
    _notificationDataStreamController.close();
  }

}