import 'dart:convert';
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
      if(!isLoading.value){
        if(checkEmailValid(emailController.text.trim()) == false){
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Alert!!!', style: TextStyle(fontSize: defaultTextFontSize)),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text('Email format is invalid.', style: TextStyle(fontSize: defaultTextFontSize)),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Ok', style: TextStyle(fontSize: defaultTextFontSize)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }else{  
          String stringified = jsonEncode({
            'email': emailController.text.trim(),
            'password': passwordController.text.trim(),
          });
          if(mounted){
            isLoading.value = true;
            var res = await dio.post('$serverDomainAddress/users/loginWithEmail', data: stringified);
            if(res.data.isNotEmpty){
              if(res.data['message'] == 'Login successful'){
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
                if(mounted){
                  updateUserData(userProfileDataClass);
                  updateUserSocials(userProfileDataClass, userSocialClass);
                }
                SharedPreferencesClass().updateCurrentUser(res.data['userID'], AppLifecycleState.resumed);
                runDelay(() => Navigator.pushAndRemoveUntil(
                  context,
                  SliderRightToLeftRoute(
                    page: const MainPageWidget()),
                  (Route<dynamic> route) => false
                ), navigatorDelayTime);
              }else{
                if(mounted){
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Alert!!!', style: TextStyle(fontSize: defaultTextFontSize)),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: [
                              Text(res.data['message'], style: TextStyle(fontSize: defaultTextFontSize)),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Continue', style: TextStyle(fontSize: defaultTextFontSize)),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              }
              if(mounted){
                isLoading.value = false;
              }
            }
          }
        }
      }
    } on Exception catch (e) {
      
    }
  }

  void loginWithUsername() async{
    try {
      if(!isLoading.value){
        if(checkUsernameValid(usernameController.text.trim()) == false){
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Alert!!!', style: TextStyle(fontSize: defaultTextFontSize)),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text('Username format is invalid.', style: TextStyle(fontSize: defaultTextFontSize)),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Ok', style: TextStyle(fontSize: defaultTextFontSize)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }else{  
          String stringified = jsonEncode({
            'username': usernameController.text.trim(),
            'password': passwordController.text.trim(),
          });
          if(mounted){
            isLoading.value = true;
            var res = await dio.post('$serverDomainAddress/users/loginWithUsername', data: stringified);
            if(res.data.isNotEmpty){
              if(res.data['message'] == 'Login successful'){
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
                if(mounted){
                  updateUserData(userProfileDataClass);
                  updateUserSocials(userProfileDataClass, userSocialClass);
                }
                SharedPreferencesClass().updateCurrentUser(res.data['userID'], AppLifecycleState.resumed);
                runDelay(() => Navigator.pushAndRemoveUntil(
                  context,
                  SliderRightToLeftRoute(
                    page: const MainPageWidget()),
                  (Route<dynamic> route) => false
                ), navigatorDelayTime);
              }else{
                if(mounted){
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Alert!!!', style: TextStyle(fontSize: defaultTextFontSize)),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: [
                              Text(res.data['message'], style: TextStyle(fontSize: defaultTextFontSize)),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Continue', style: TextStyle(fontSize: defaultTextFontSize)),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              }
              if(mounted){
                isLoading.value = false;
              }
            }
          }
        }
      }
    } on Exception catch (e) {
      
    }
  }

}