import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class GlobalObserver extends WidgetsBindingObserver{
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async{
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        debugPrint('appLifeCycleState inactive');
        break;
      case AppLifecycleState.resumed:
        debugPrint('appLifeCycleState resumed');
        Map map = await secureStorageController.readUserState();
        if(map['last_lifecycle_state'] != null){
          AutoNavigateLifecycleStreamClass().emitData(
            AutoNavigateLifecycleStreamControllerClass(
              map['last_lifecycle_state'],
              map['last_lifecycle_time'],
            )
          );
        }
        break;
      case AppLifecycleState.paused:
        debugPrint('appLifeCycleState paused');
        secureStorageController.writeUserState(
          AppLifecycleState.paused.name, 
          DateTime.now().toIso8601String()
        );
        break;
      case AppLifecycleState.detached:
        debugPrint('appLifeCycleState detached');
        secureStorageController.writeUserState(
          AppLifecycleState.detached.name, 
          DateTime.now().toIso8601String()
        );
        socket.disconnect();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}
