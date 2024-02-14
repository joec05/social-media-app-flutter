import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:social_media_app/global_files.dart';

class AuthenticationRepository {
  ValueNotifier<User?> currentUser = ValueNotifier(null);
  final _instance = FirebaseAuth.instance;

  User? get user => currentUser.value;
  String get userID => user?.uid ?? '';
  String get email => user?.email ?? '';
  String get name => user?.displayName ?? '';

  void initializeAuthListener() {
    currentUser.value = _instance.currentUser;
    _instance.userChanges().listen((event) async{
      currentUser.value = event;
      if(event != null) {
        appStateRepo.currentID = event.uid;
      }else{
        appStateRepo.resetSession();
      }
    });
  }

  Future<void> createUserWithEmailAndPassword(
    BuildContext context,
    String email, 
    String password
  ) async{
    try {
      await _instance.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
    } on FirebaseAuthException catch(e) {
      final message = 'Error ${e.code}: ${e.message ?? tErr.firebase}';
      if(context.mounted) {
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          message
        );
      }
    }
  }

  Future<void> sendEmailVerification(
    BuildContext context,
  ) async{
    try {
      await _instance.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch(e) {
      final message = 'Error ${e.code}: ${e.message ?? tErr.firebase}';
      if(context.mounted) {
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          message
        );
      }
    }
  }

  Future<void> loginUserWithEmailAndPassword(
    BuildContext context,
    String email, 
    String password
  ) async{
    try {
      await _instance.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
    } on FirebaseAuthException catch(e) {
      final message = 'Error ${e.code}: ${e.message ?? tErr.firebase}';
      if(context.mounted) {
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          message
        );
      }
    }
  }

  Future<void> resetPassword(BuildContext context, String email) async{
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
      if(context.mounted) {
        handler.displaySnackbar(
          context,
          SnackbarType.regular, 
          'An email has been sent to $email, check your inbox!'
        );
      }
    } on FirebaseAuthException catch(e) {
      final message = 'Error ${e.code}: ${e.message ?? tErr.firebase}';
      if(context.mounted) {
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          message
        );
      }
    }
  }

  Future<void> logOut(BuildContext context) async{
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      secureStorageController.writeUserState(null, null);
    } on FirebaseAuthException catch(e) {
      final message = 'Error ${e.code}: ${e.message ?? tErr.firebase}';
      if(context.mounted) {
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          message
        );
      }
    }
  }

  Future<void> deleteEmailPasswordAccount(
    BuildContext context,
    String email,
    String password
  ) async {
    try {
      await _instance.currentUser?.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password)
      ).then((value) async {
        await _instance.currentUser?.delete();
        logOut(context);
      });
    } on FirebaseAuthException catch(e) {
      final message = 'Error ${e.code}: ${e.message ?? tErr.firebase}';
      if(context.mounted) {
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          message
        );
      }
    }
  }
}

final authRepo = AuthenticationRepository();