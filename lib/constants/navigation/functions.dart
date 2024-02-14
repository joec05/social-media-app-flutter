import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

PageRouteBuilder generatePageRouteBuilder(RouteSettings? settings, Widget child){
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child
    ) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0), end: Offset.zero
      ).animate(animation), child: child
    )
  );
}

void navigateToProfilePage(BuildContext context, String userID) async{
  runDelay(()async => await Navigator.push(
    context,
    SliderRightToLeftRoute(
      page: ProfilePageWidget(userID: userID)
    )
  ), navigatorDelayTime);
}

void navigateBackToInitialScreen(BuildContext context) async{
  runDelay(()async => await Navigator.pushAndRemoveUntil(
    context,
    SliderRightToLeftRoute(
      page: const SocialMediaApp()
    ),
    (Route<dynamic> route) => false
  ), navigatorDelayTime);
}