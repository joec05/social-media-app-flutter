import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class LoginController {
  BuildContext context;
  TextEditingController emailController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  ValueNotifier<bool> verifyEmailFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyUsernameFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyPasswordFormat = ValueNotifier(false);
  final int usernameCharacterMinLimit = profileInputMinLimit['username'];
  final int passwordCharacterMinLimit = profileInputMinLimit['password'];
  final int usernameCharacterMaxLimit = profileInputMaxLimit['username'];
  final int passwordCharacterMaxLimit = profileInputMaxLimit['password'];
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  
  LoginController(
    this.context
  );

  bool get mounted => context.mounted;

  void initializeController(){
    emailController.addListener(() {
      if(mounted){
        String emailText = emailController.text;
        verifyEmailFormat.value = emailText.isNotEmpty && checkEmailValid(emailText);
      }
    });
    usernameController.addListener(() {
      if(mounted){
        String usernameText = usernameController.text;
        verifyUsernameFormat.value = usernameText.isNotEmpty && checkUsernameValid(usernameText) &&
        usernameText.length >= usernameCharacterMinLimit && usernameText.length <= usernameCharacterMaxLimit;
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

  void dispose(){
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    verifyEmailFormat.dispose();
    verifyUsernameFormat.dispose();
    verifyPasswordFormat.dispose();
    isLoading.dispose();
  }
  
  void loginWithEmail() async{
    try {
      if(mounted){
        if(!isLoading.value){
          if(checkEmailValid(emailController.text.trim()) == false){
            handler.displaySnackbar(
              context,
              SnackbarType.error,
              'Email format is invalid'
            );
          }else{  
            if(mounted){
              isLoading.value = true;
              await authRepo.loginUserWithEmailAndPassword(
                context, 
                emailController.text.trim(), 
                passwordController.text.trim()
              ).then((value) async{
                isLoading.value = false;
                User? user = authRepo.currentUser.value;
                if(user != null){
                  isLoading.value = true;
                  var verified = authRepo.currentUser.value?.emailVerified == false ? 
                    await Navigator.push(
                      context,
                      SliderRightToLeftRoute(
                        page: const EmailVerificationPage()
                      )
                    )
                  : true;
                  if(verified == true && mounted){
                    dynamic res = await fetchDataRepo.fetchData(
                      context, 
                      RequestPost.loginWithEmail, 
                      {
                        'email': emailController.text.trim(),
                      }
                    );
                    if(mounted){
                      isLoading.value = false;
                      if(res != null) {
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
                        secureStorageController.writeUserState(
                          AppLifecycleState.resumed.name, 
                          DateTime.now().toIso8601String()
                        );
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

  void resetPassword(BuildContext context) async{
    if(mounted){
      if(!isLoading.value){
        if(emailController.text.isEmpty){
          handler.displaySnackbar(
            context,
            SnackbarType.error,
            'Please fill your email'
          );
        }else if(checkEmailValid(emailController.text.trim()) == false){
          handler.displaySnackbar(
            context,
            SnackbarType.error,
            'Email format is invalid'
          );
        }else{  
          authRepo.resetPassword(context, emailController.text.trim());
        }
      }
    }
  }
}