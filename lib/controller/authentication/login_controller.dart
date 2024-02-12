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
            dynamic res = await fetchDataRepo.fetchData(
              context, 
              RequestPost.loginWithEmail, 
              {
                'email': emailController.text.trim(),
                'password': passwordController.text.trim(),
              }
            );
            if(mounted){
              isLoading.value = false;
              if(res != null) {
                appStateClass.currentID = res.data['userID'];
                Map userProfileData = (res.data['userProfileData']);
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
                SharedPreferencesClass().updateCurrentUser(res.data['userID'], AppLifecycleState.resumed);
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
      }
    }
  }

  void loginWithUsername() async{
    if(mounted){
      if(!isLoading.value){
        if(checkUsernameValid(usernameController.text.trim()) == false){
          handler.displaySnackbar(
            context,
            SnackbarType.error,
            'Username format is invalid'
          );
        }else{
          if(mounted){
            isLoading.value = true;
            dynamic res = await fetchDataRepo.fetchData(
              context, 
              RequestPost.loginWithUsername, 
              {
                'username': usernameController.text.trim(),
                'password': passwordController.text.trim(),
              }
            );
            if(mounted) {
              isLoading.value = false;
              if(res != null) {
                appStateClass.currentID = res.data['userID'];
                Map userProfileData = (res.data['userProfileData']);
                UserDataClass userProfileDataClass = UserDataClass(
                  userProfileData['user_id'], userProfileData['name'], userProfileData['username'], userProfileData['profile_picture_link'], 
                  userProfileData['date_joined'], userProfileData['birth_date'], userProfileData['bio'], 
                  false, false, false, userProfileData['private'], false, false, userProfileData['verified'],
                  false, false
                );
                UserSocialClass userSocialClass = UserSocialClass(
                  0, 0, false, false
                );
                updateUserData(userProfileDataClass);
                updateUserSocials(userProfileDataClass, userSocialClass);
                SharedPreferencesClass().updateCurrentUser(res.data['userID'], AppLifecycleState.resumed);
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
      }
    }
  }
}