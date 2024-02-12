import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SignUpController {
  BuildContext context;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  DateTime selectedBirthDate = DateTime.now();
  ValueNotifier<bool> verifyNameFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyUsernameFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyEmailFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyPasswordFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyBirthDateFormat = ValueNotifier(false);
  final int nameCharacterMaxLimit = profileInputMaxLimit['name'];
  final int usernameCharacterMinLimit = profileInputMinLimit['username'];
  final int passwordCharacterMinLimit = profileInputMinLimit['password'];
  final int usernameCharacterMaxLimit = profileInputMaxLimit['username'];
  final int passwordCharacterMaxLimit = profileInputMaxLimit['password'];

  SignUpController(
    this.context
  );

  bool get mounted => context.mounted;

  void initializeController(){
    nameController.addListener(() {
      if(mounted){
        String nameText = nameController.text;
        verifyNameFormat.value = nameText.isNotEmpty && nameText.length <= nameCharacterMaxLimit;
      }
    });
    usernameController.addListener(() {
      if(mounted){
        String usernameText = usernameController.text;
        verifyUsernameFormat.value = usernameText.isNotEmpty && checkUsernameValid(usernameText) &&
        usernameText.length >= usernameCharacterMinLimit && usernameText.length <= usernameCharacterMaxLimit;
      }
    });
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
    birthDateController.addListener(() {
      if(mounted){
        String birthDateText = birthDateController.text;
        verifyBirthDateFormat.value = birthDateText.isNotEmpty;
      }
    });
  }

  void dispose(){
    isLoading.dispose();
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    birthDateController.dispose();
    verifyNameFormat.dispose();
    verifyUsernameFormat.dispose();
    verifyEmailFormat.dispose();
    verifyPasswordFormat.dispose();
    verifyBirthDateFormat.dispose();
  }
  
  Future<void> selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthDate,
      firstDate: DateTime(1945, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked! != selectedBirthDate){
      selectedBirthDate = picked;
      int day = picked.day;
      int month = picked.month;
      int year = picked.year;
      birthDateController.text = '$day/$month/$year';
    }
  }

  Future<dynamic> checkAccountExistsSignUp() async{
    dynamic res = await fetchDataRepo.fetchData(
      context, 
      RequestGet.checkAccountExistsSignUp, 
      {
        'email': emailController.text.trim(),
        'username': usernameController.text.trim(),
      }
    );
    return res;
  }

  void signUp() async{
    if(mounted){
      if(!isLoading.value){
        if(checkUsernameValid(usernameController.text.trim()) == false){
          handler.displaySnackbar(
            context,
            SnackbarType.error,
            'The username is invalid'
          );
        }else{  
          try {
            var verifyAccountExistence = await checkAccountExistsSignUp();
            if(verifyAccountExistence != null && mounted){
              if(verifyAccountExistence['exists']){
                handler.displaySnackbar(
                  context,
                  SnackbarType.error,
                  'Email or username has already been used'
                );
              }else{
                await auth.createUserWithEmailAndPassword(
                  email: emailController.text, password: passwordController.text
                ).then((value) async{
                  var verified = await Navigator.push(
                    context,
                    SliderRightToLeftRoute(
                      page: const EmailVerificationPage()
                    )
                  );
                  if(verified == true && mounted){
                    isLoading.value = true;
                    dynamic res = await fetchDataRepo.fetchData(
                      context, 
                      RequestPost.signUp, 
                      {
                        'name': nameController.text.trim(),
                        'username': usernameController.text.trim(),
                        'profilePicLink': defaultUserProfilePicLink,
                        'email': emailController.text.trim(),
                        'password': passwordController.text.trim(),
                        'birthDate': selectedBirthDate.toString()
                      }
                    );
                    if(mounted) {
                      isLoading.value = false;
                      if(res != null) {
                        appStateClass.currentID = res.data['userID'];
                        UserDataClass userDataClass = UserDataClass(
                          res.data['userID'], nameController.text.trim(), usernameController.text.trim(), defaultUserProfilePicLink,
                          DateTime.now().toString(), selectedBirthDate.toString(), '',  false, false, false, false,
                          false, false, false, false, false
                        );
                        UserSocialClass userSocialClass = UserSocialClass(
                          0, 0, false, false
                        );
                        updateUserData(userDataClass);
                        updateUserSocials(userDataClass, userSocialClass);
                        SharedPreferencesClass().updateCurrentUser(res.data['userID'], AppLifecycleState.resumed);
                        runDelay(() => Navigator.push(
                          context,
                          SliderRightToLeftRoute(
                            page: const CompleteSignUpProfileStateless()
                          )
                        ), navigatorDelayTime);
                      }
                    }
                  }
                });
              }
            }
          } on FirebaseAuthException catch (e) {
            if(mounted){
              isLoading.value = false;
              if (e.code == 'weak-password') {
                handler.displaySnackbar(
                  context, 
                  SnackbarType.error, 
                  'The password is too weak'
                );
              } else if (e.code == 'email-already-in-use') {
                handler.displaySnackbar(
                  context, 
                  SnackbarType.error, 
                  'The email has already been used'
                );
              }else if (e.code == 'invalid-email') {
                handler.displaySnackbar(
                  context, 
                  SnackbarType.error, 
                  'Invalid email format'
                );
              }
            }
            return null;
          } catch (e) {
            debugPrint(e.toString());
            return null;
          }
        }
      }
    }
  }

}