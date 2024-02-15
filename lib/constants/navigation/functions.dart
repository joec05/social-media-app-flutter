import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

/// Creates a page route builder. This is needed to declare named routes for a specific page.
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

/// Remove all active routes then navigates the user into the home page
void navigateBackToInitialScreen(BuildContext context) async{
  runDelay(()async => await Navigator.pushAndRemoveUntil(
    context,
    SliderRightToLeftRoute(
      page: const SocialMediaApp()
    ),
    (Route<dynamic> route) => false
  ), navigatorDelayTime);
}