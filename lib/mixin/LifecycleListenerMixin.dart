import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalVariables.dart';
import 'package:social_media_app/streams/AutoNavigateLifecycleStreamClass.dart';
import '../appdata/AppStateActions.dart';

mixin LifecycleListenerMixin<T extends StatefulWidget> on State<T>{
  Function? _changeBottomNavIndex;
  GlobalKey<ScaffoldState>? _scaffoldKey;

  void initLifecycleListener({
    required Function changeBottomNavIndex,
    required GlobalKey<ScaffoldState> scaffoldKey
  }){
    _changeBottomNavIndex = changeBottomNavIndex;
    _scaffoldKey = scaffoldKey;
  }

  @override
  void initState(){
    super.initState();
    AutoNavigateLifecycleStreamClass().addListener((AutoNavigateLifecycleStreamControllerClass data) {
      if(mounted){
        int timeDifference = DateTime.now().difference(DateTime.parse(data.lastLifecycleTime).toLocal()).inMinutes;
        if(data.lastLifecycleState == AppLifecycleState.paused.name){
          if(timeDifference > timeDifferenceToLogOut){
            logOut(context);
          }else if(timeDifference > timeDifferenceToMainPage){
            Navigator.of(context).popUntil((route) => route.isFirst);
            _changeBottomNavIndex?.call();
            if (_scaffoldKey?.currentState?.isDrawerOpen ?? false){
              _scaffoldKey?.currentState!.closeDrawer();
            }
          }
        }else if(data.lastLifecycleState == AppLifecycleState.detached.name){
          if(timeDifference > timeDifferenceToLogOut){
            logOut(context);
          }
        }
      }
    });
  }
}