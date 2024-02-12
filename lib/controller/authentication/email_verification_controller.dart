import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class EmailVerificationController {
  BuildContext context;
  ValueNotifier<bool> verified = ValueNotifier(false);
  Timer? timer;

  EmailVerificationController(
    this.context
  );

  bool get mounted => context.mounted;

  void initializeController() {
    authRepo.sendEmailVerification(context);
    timer = Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
  }

  void dispose() {
    timer?.cancel();
  }

  void checkEmailVerified() async {
    await auth.currentUser?.reload().then((value){
      if(mounted){
        verified.value = auth.currentUser!.emailVerified;
        if(verified.value) {
          timer?.cancel();
          Navigator.pop(context, verified);
        }
      }
    });
  }
}