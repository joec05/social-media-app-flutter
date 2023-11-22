import 'dart:async';

class AutoNavigateLifecycleStreamControllerClass{
  final String lastLifecycleTime;
  final String lastLifecycleState;

  AutoNavigateLifecycleStreamControllerClass(this.lastLifecycleState, this.lastLifecycleTime);
}

class AutoNavigateLifecycleStreamClass {
  static final AutoNavigateLifecycleStreamClass _instance = AutoNavigateLifecycleStreamClass._internal();
  late StreamController<AutoNavigateLifecycleStreamControllerClass> _autoNavigateLifecycleStreamController;
  late StreamSubscription autoNavigateLifecycleStreamClassSubscription;

  factory AutoNavigateLifecycleStreamClass(){
    return _instance;
  }

  AutoNavigateLifecycleStreamClass._internal() {
    _autoNavigateLifecycleStreamController = StreamController<AutoNavigateLifecycleStreamControllerClass>.broadcast();
  }

  Stream<AutoNavigateLifecycleStreamControllerClass> get autoNavigateLifecycleStream => _autoNavigateLifecycleStreamController.stream;

  void addListener(void Function(AutoNavigateLifecycleStreamControllerClass) onData){
    autoNavigateLifecycleStreamClassSubscription = autoNavigateLifecycleStream.listen((AutoNavigateLifecycleStreamControllerClass data) {
      onData(data);
    });
  }

  void cancel(){
    autoNavigateLifecycleStreamClassSubscription.cancel();
  }

  void removeListener(){
    _autoNavigateLifecycleStreamController.stream.drain();
  }

  void emitData(AutoNavigateLifecycleStreamControllerClass data){
   if(!_autoNavigateLifecycleStreamController.isClosed){
     _autoNavigateLifecycleStreamController.add(data);
   }
  }

  void dispose(){
    _autoNavigateLifecycleStreamController.close();
  }

}