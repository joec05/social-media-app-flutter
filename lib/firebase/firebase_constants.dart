import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/firebase/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

final Future<FirebaseApp> firebaseInitialization = Firebase.initializeApp(
  name: "flutter-social-media-app-7aac7",
  options: DefaultFirebaseOptions.currentPlatform
).whenComplete((){
  debugPrint('Completed initialization to Firebase');
});

final firebaseAppCheckInitialization = FirebaseAppCheck.instance.activate(
  webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.appAttest,
);

FirebaseAuth auth = FirebaseAuth.instance;