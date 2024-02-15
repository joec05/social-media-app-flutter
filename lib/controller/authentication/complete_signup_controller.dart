import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

/// Controller which is used when a new user has verified the given email. The user will need to
/// complete the sign up process by uploading a profile picture and may as well insert a bio.
class CompleteSignUpController {

  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;
  
  /// Variable to store the file path of a selected image
  ValueNotifier<String> imageFilePath = ValueNotifier('');

  /// An editing controller for the user to insert a bio
  TextEditingController bioController = TextEditingController();
  
  /// True if the bio is in acceptable format
  ValueNotifier<bool> verifyBioFormat = ValueNotifier(false);
  
  /// Maximum length of a bio
  final int bioCharacterMaxLimit = profileInputMaxLimit['bio'];
  
  /// True if an API/Firebase/AppWrite function is running
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  CompleteSignUpController(
    this.context
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    bioController.addListener(() {
      if(mounted){
        String bioText = bioController.text;
        verifyBioFormat.value = bioText.isNotEmpty && bioText.length <= bioCharacterMaxLimit
        && bioText.length <= bioCharacterMaxLimit;
      }
    });
  }

  /// Dispose everything. Called at every page's dispose function
  void dispose(){
    imageFilePath.dispose();
    bioController.dispose();
    verifyBioFormat.dispose();
    isLoading.dispose();
  }
  
  /// Called when the user pressed the given button
  void completeSignUpProfile() async{
    if(mounted){
      if(!isLoading.value){
        isLoading.value = true;

        /// Upload the selected image to AppWrite and get the url
        String uploadProfilePic = await cloudController.uploadImageToAppWrite(context, imageFilePath.value);
        
        if(mounted){

          /// Call the API to store the profile picture's url and bio
          dynamic res = await fetchDataRepo.fetchData(
            context, 
            RequestPost.completeSignUpProfile, 
            {
              'userId': appStateRepo.currentID,
              'profilePicLink': uploadProfilePic,
              'bio': bioController.text.trim(),
            }
          );

          if(mounted){
            isLoading.value = false;

            /// If res is not null, the API call is successful
            if(res != null) {

              /// Update the profile picture at the app state repository
              appStateRepo.usersDataNotifiers.value[appStateRepo.currentID]!.notifier.value.profilePicLink = uploadProfilePic;
              
              /// Navigate to main page
              runDelay(() => Navigator.pushAndRemoveUntil(
                context,
                SliderRightToLeftRoute(
                  page: const MainPageWidget()
                ),
                (Route<dynamic> route) => false
              ), navigatorDelayTime);
            }
          }
        }
      }
    }
  }

  /// Function to pick image
  Future<void> pickImage() async {

    /// Handle permission
    bool permissionIsGranted = false;
    ph.Permission? permission;
    if(Platform.isAndroid){
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if(androidInfo.version.sdkInt <= 32){
        permission = ph.Permission.storage;
      }else{
        permission = ph.Permission.photos;
      }
    }
    permissionIsGranted = await permission!.isGranted;
    if(!permissionIsGranted){
      await permission.request();
      permissionIsGranted = await permission.isGranted;
    }

    /// Proceed once permission is granted
    if(permissionIsGranted){
      try {
        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
        if(pickedFile != null && mounted){

          /// Update the variable once image is selected
          imageFilePath.value = pickedFile.path;
        }
      } catch(e) {
        debugPrint('Failed to pick image: $e');
      }
    }
  }
}