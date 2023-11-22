import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/caching/sqfliteConfiguration.dart';
import 'package:social_media_app/streams/AutoNavigateLifecycleStreamClass.dart';
import '../socket/main.dart';

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
        List<Map> usersLifecycleData = await DatabaseHelper().getAllUsersLifecycleData();
        if(usersLifecycleData.isNotEmpty && usersLifecycleData[0]['last_lifecycle_state'].isNotEmpty){
          Map userLifecycleData = usersLifecycleData[0];
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
        DatabaseHelper().updateUserLifecycleData(fetchReduxDatabase().currentID, AppLifecycleState.paused);
        break;
      case AppLifecycleState.detached:
        debugPrint('appLifeCycleState detached');
        DatabaseHelper().updateUserLifecycleData(fetchReduxDatabase().currentID, AppLifecycleState.detached);
        socket.disconnect();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}
