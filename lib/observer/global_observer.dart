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
        Map userLifecycleData = await SharedPreferencesClass().fetchCurrentUser();
        if(userLifecycleData['last_lifecycle_state'].isNotEmpty){
          AutoNavigateLifecycleStreamClass().emitData(
            AutoNavigateLifecycleStreamControllerClass(
              userLifecycleData['last_lifecycle_state'],
              userLifecycleData['last_lifecycle_time'],
            )
          );
        }
        break;
      case AppLifecycleState.paused:
        debugPrint('appLifeCycleState paused');
        SharedPreferencesClass().updateCurrentUser(appStateClass.currentID, AppLifecycleState.paused);
        break;
      case AppLifecycleState.detached:
        debugPrint('appLifeCycleState detached');
        SharedPreferencesClass().updateCurrentUser(appStateClass.currentID, AppLifecycleState.detached);
        socket.disconnect();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}
