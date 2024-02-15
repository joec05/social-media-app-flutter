import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

/// Controller which is used when the user wants to login
class LoginController {

  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// An editing controller for the user to insert an email
  TextEditingController emailController = TextEditingController();

  /// An editing controller for the user to insert a password
  TextEditingController passwordController = TextEditingController();

  /// True if the email is in acceptable format
  ValueNotifier<bool> verifyEmailFormat = ValueNotifier(false);

  /// True if the password is in acceptable format
  ValueNotifier<bool> verifyPasswordFormat = ValueNotifier(false);

  /// Minimum length of a password
  final int passwordCharacterMinLimit = profileInputMinLimit['password'];

  /// Maximum length of a password
  final int passwordCharacterMaxLimit = profileInputMaxLimit['password'];

  /// True if an API/Firebase/AppWrite function is running
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  
  LoginController(
    this.context
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    emailController.addListener(() {
      if(mounted){
        String emailText = emailController.text;
        verifyEmailFormat.value = emailText.isNotEmpty && checkEmailValid(emailText);
      }
    });
    passwordController.addListener(() {
      if(mounted){
        String passwordText = passwordController.text;
        verifyPasswordFormat.value = passwordText.isNotEmpty && passwordText.length >= passwordCharacterMinLimit
        && passwordText.length <= passwordCharacterMaxLimit;
      }
    });
  }

  /// Dispose everything. Called at every page's dispose function
  void dispose(){
    emailController.dispose();
    passwordController.dispose();
    verifyEmailFormat.dispose();
    verifyPasswordFormat.dispose();
    isLoading.dispose();
  }
  
  /// Called when the user pressed the given button
  void loginWithEmail() async{
    try {
      if(mounted){
        if(!isLoading.value){

          /// Check if the email is valid. If true proceed otherwise return a snackbar error
          if(checkEmailValid(emailController.text.trim()) == false){
            handler.displaySnackbar(
              context,
              SnackbarType.error,
              'Email format is invalid'
            );
          }else{  
            if(mounted){
              isLoading.value = true;

              /// Call authentication repository to login the user with email and password to FirebaseAuth
              await authRepo.loginUserWithEmailAndPassword(
                context, 
                emailController.text.trim(), 
                passwordController.text.trim()
              ).then((value) async{
                isLoading.value = false;
                User? user = authRepo.currentUser.value;
                if(user != null){
                  isLoading.value = true;

                  /// Check if the user's email is verified
                  var verified = authRepo.currentUser.value?.emailVerified == false ? 

                    /// If the email is unverified automatically navigate the user to the email verification page to verify the user's email
                    await Navigator.push(
                      context,
                      SliderRightToLeftRoute(
                        page: const EmailVerificationPage()
                      )
                    )

                  : true;

                  if(verified == true && mounted){

                    /// Call the API to log the user in
                    dynamic res = await fetchDataRepo.fetchData(
                      context, 
                      RequestPost.loginWithEmail, 
                      {
                        'email': emailController.text.trim(),
                      }
                    );

                    if(mounted){
                      isLoading.value = false;

                      /// If res is not null, the API call is successful
                      if(res != null) {

                        /// Start updating the current id, user data, and user socials at the app state repository
                        appStateRepo.currentID = res['userID'];
                        Map userProfileData = (res['userProfileData']);
                        UserDataClass userProfileDataClass = UserDataClass(
                          userProfileData['user_id'], userProfileData['name'], userProfileData['username'], userProfileData['profile_picture_link'], 
                          userProfileData['date_joined'], userProfileData['birth_date'], userProfileData['bio'], 
                          false, false, false, userProfileData['private'], false, false, userProfileData['verified'], false, false
                        );
                        UserSocialClass userSocialClass = UserSocialClass(
                          0, 0, false, false
                        );
                        updateUserData(userProfileDataClass);
                        updateUserSocials(userProfileDataClass, userSocialClass);

                        /// Store the current lifecycle state of the app in a secured storage
                        secureStorageController.writeUserState(
                          AppLifecycleState.resumed.name, 
                          DateTime.now().toIso8601String()
                        );

                        /// Navigate to main page
                        runDelay(() => Navigator.pushAndRemoveUntil(
                          context,
                          SliderRightToLeftRoute(
                            page: const MainPageWidget()),
                          (Route<dynamic> route) => false
                        ), navigatorDelayTime);

                      }
                    }
                  }
                }
              });
            }
          }
        }
      }
    } catch (_) {
      isLoading.value = false;
    }
  }

  /// Called when the user pressed the 'Forgot your password?' text widget
  void resetPassword(BuildContext context) async{
    if(mounted){
      if(!isLoading.value){

        if(emailController.text.isEmpty){

          /// Returns a snackbar error if the user hasn't typed anything
          handler.displaySnackbar(
            context,
            SnackbarType.error,
            'Please fill your email'
          );

        }else if(checkEmailValid(emailController.text.trim()) == false){

          /// Returns a snackbar error if the email format is invalid
          handler.displaySnackbar(
            context,
            SnackbarType.error,
            'Email format is invalid'
          );

        }else{  

          /// Call on the authentication repository to reset the user's password by sending an email to the given email address
          authRepo.resetPassword(context, emailController.text.trim());

        }
      }
    }
  }
}