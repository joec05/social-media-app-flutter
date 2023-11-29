import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/firebase/firebase_options.dart';

final Future<FirebaseApp> firebaseInitialization = Firebase.initializeApp(
  name: "flutter-social-media-app-7aac7",
  options: DefaultFirebaseOptions.currentPlatform
).whenComplete((){
  debugPrint('Completed initialization to Firebase');
});

FirebaseAuth auth = FirebaseAuth.instance;