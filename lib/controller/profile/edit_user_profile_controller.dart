import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

class EditUserProfileController {
  BuildContext context;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  ValueNotifier<String> imageFilePath = ValueNotifier('');
  ValueNotifier<String> imageNetworkPath = ValueNotifier('');
  DateTime selectedBirthDate = DateTime.now();
  ValueNotifier<bool> verifyNameFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyUsernameFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyBirthDateFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyBioFormat = ValueNotifier(false);
  final int nameCharacterMaxLimit = profileInputMaxLimit['name'];
  final int usernameCharacterMinLimit = profileInputMinLimit['username'];
  final int usernameCharacterMaxLimit = profileInputMaxLimit['username'];
  final int passwordCharacterMaxLimit = profileInputMaxLimit['password'];
  final int bioCharacterMaxLimit = profileInputMaxLimit['bio'];

  EditUserProfileController(
    this.context
  );
  
  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchUserProfileData(), actionDelayTime);
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
    birthDateController.addListener(() {
      if(mounted){
        String birthDateText = birthDateController.text;
        verifyBirthDateFormat.value = birthDateText.isNotEmpty;
      }
    });
    bioController.addListener(() {
      if(mounted){
        String bioText = bioController.text;
        verifyBioFormat.value = bioText.isNotEmpty && bioText.length <= bioCharacterMaxLimit
        && bioText.length <= bioCharacterMaxLimit;
      }
    });
  }

  void dispose(){
    isLoading.dispose();
    nameController.dispose();
    usernameController.dispose();
    birthDateController.dispose();
    bioController.dispose();
    verifyNameFormat.dispose();
    verifyUsernameFormat.dispose();
    verifyBirthDateFormat.dispose();
    verifyBioFormat.dispose();
    imageFilePath.dispose();
    imageNetworkPath.dispose();
  }

  void fetchUserProfileData() async{
    if(mounted){
      isLoading.value = true;
      dynamic res = await fetchDataRepo.fetchData(
        context, 
        RequestGet.fetchCurrentUserProfile, 
        {
          'currentID': appStateClass.currentID
        }
      );
      if(mounted){
        isLoading.value = false;
        if(res != null){
          Map userProfileData = res.data['userProfileData'];
          nameController.text = userProfileData['name'];
          usernameController.text = userProfileData['username'];
          bioController.text = userProfileData['bio'];
          imageNetworkPath.value = userProfileData['profile_picture_link'];
          DateTime parsedBirthDate = DateTime.parse(userProfileData['birth_date']);
          selectedBirthDate = parsedBirthDate;
          birthDateController.text = '${parsedBirthDate.day}/${parsedBirthDate.month}/${parsedBirthDate.year}';
        }
      }
    }
  }
  
  Future<void> selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthDate,
      firstDate: DateTime(1945, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedBirthDate){
      selectedBirthDate = picked;
      int day = picked.day;
      int month = picked.month;
      int year = picked.year;
      birthDateController.text = '$day/$month/$year';
    }
  }

  Future<void> pickImage() async {
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

    if(permissionIsGranted){
      try {
        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
        if(pickedFile != null && mounted){
          imageFilePath.value = pickedFile.path;
          imageNetworkPath.value = '';
        }
      } catch(e) {
        debugPrint('Failed to pick image: $e');
      }
    }
  }

  void editProfile() async{
    if(mounted) {
      if(!isLoading.value){
        if(checkUsernameValid(usernameController.text.trim()) == false){
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            'Username format is invalid.'
          );
        }else{  
          String currentID = appStateClass.currentID;
          String nameText = nameController.text.trim();
          String usernameText = usernameController.text.trim();
          String imagePath = '';
          if(imageFilePath.value.isNotEmpty){
            imagePath = await cloudController.uploadImageToAppWrite(
              context,
              imageFilePath.value
            );
          }else{
            imagePath = imageNetworkPath.value;
          }
          if(mounted){
            dynamic res = await fetchDataRepo.fetchData(
              context, 
              RequestPatch.editUserProfile, 
              {
                'userID': currentID,
                'name': nameText,
                'username': usernameText,
                'profilePicLink': imagePath,
                'bio': bioController.text.trim(),
                'birthDate': selectedBirthDate.toString()
              }
            );
            if(mounted){
              if(res != null){
                UserDataClass currentUserProfileDataClass = appStateClass.usersDataNotifiers.value[currentID]!.notifier.value;
                UserDataClass updatedCurrentUserProfileDataClass = UserDataClass(
                  currentID, nameText, usernameText, imagePath, currentUserProfileDataClass.dateJoined, 
                  selectedBirthDate.toString(), bioController.text.trim(),
                  currentUserProfileDataClass.mutedByCurrentID, currentUserProfileDataClass.blockedByCurrentID, 
                  currentUserProfileDataClass.blocksCurrentID, currentUserProfileDataClass.private,
                  currentUserProfileDataClass.requestedByCurrentID, currentUserProfileDataClass.requestsToCurrentID,
                  currentUserProfileDataClass.verified, currentUserProfileDataClass.suspended, currentUserProfileDataClass.deleted
                );
                appStateClass.usersDataNotifiers.value[currentID]!.notifier.value = updatedCurrentUserProfileDataClass;
                Navigator.pop(context);
              }
            }
          }
        }
      }
    }
  }
}