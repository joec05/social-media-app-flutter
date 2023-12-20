import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/global_functions.dart';
import 'package:social_media_app/appdata/global_variables.dart';
import 'package:social_media_app/transition/right_to_left_transition.dart';
import '../profile_page.dart';
import '../main.dart';

void navigateToProfilePage(BuildContext context, String userID) async{
  try {
    runDelay(()async => await Navigator.push(
      context,
      SliderRightToLeftRoute(
        page: ProfilePageWidget(userID: userID)
      )
    ), navigatorDelayTime);
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void navigateBackToInitialScreen(BuildContext context) async{
  try {
    runDelay(()async => await Navigator.pushAndRemoveUntil(
      context,
      SliderRightToLeftRoute(
        page: const MyApp()
      ),
      (Route<dynamic> route) => false
    ), navigatorDelayTime);
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}