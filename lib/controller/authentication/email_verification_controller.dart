import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

/// Controller which is used when the user's email is being verified
class EmailVerificationController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// True if the user is successfully verified
  ValueNotifier<bool> verified = ValueNotifier(false);

  /// Timer which will be periodically run every 3 seconds to find out whether the email is verified or not
  Timer? timer;

  EmailVerificationController(
    this.context
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController() {
    authRepo.sendEmailVerification(context);
    timer = Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
  }

  /// Dispose everything. Called at every page's dispose function
  void dispose() {
    verified.dispose();
    timer?.cancel();
  }

  /// Checks whether email is verified or not
  void checkEmailVerified() async {
    await auth.currentUser?.reload().then((value){
      if(mounted){

        /// Calls the authentication repository's FirebaseAuth user to check whether email is verified or not
        verified.value = auth.currentUser!.emailVerified;
        if(verified.value) {

          /// Once user is verified, cancel timer and navigate back while passing an argument that the user is verified
          timer?.cancel();
          Navigator.pop(context, verified.value);
          
        }
      }
    });
  }
}