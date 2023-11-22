// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/custom/CustomButton.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'styles/AppStyles.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

var dio = Dio();

class EditProfileStateless extends StatelessWidget {
  const EditProfileStateless({super.key});

  @override
  Widget build(BuildContext context) {
    return const EditProfileStateful();
  }
}

class EditProfileStateful extends StatefulWidget {
  const EditProfileStateful({super.key});

  @override
  State<EditProfileStateful> createState() => _EditProfileStatefulState();
}

class _EditProfileStatefulState extends State<EditProfileStateful> with LifecycleListenerMixin{
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

  @override
  void initState(){
    super.initState();
    fetchUserProfileData();
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

  @override void dispose(){
    super.dispose();
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
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = jsonEncode({
          'currentID': fetchReduxDatabase().currentID
        });
        var res = await dio.get('$serverDomainAddress/users/fetchCurrentUserProfile', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            if(mounted){
              Map userProfileData = res.data['userProfileData'];
              nameController.text = userProfileData['name'];
              usernameController.text = userProfileData['username'];
              bioController.text = userProfileData['bio'];
              imageNetworkPath.value = userProfileData['profile_picture_link'];
              DateTime parsedBirthDate = DateTime.parse(userProfileData['birth_date']);
              selectedBirthDate = parsedBirthDate;
              birthDateController.text = '${parsedBirthDate.day}/${parsedBirthDate.month}/${parsedBirthDate.year}';
            }
          }else{
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
          if(mounted){
            isLoading.value = false;
          }
        }
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }
  
  Future<void> _selectBirthDate(BuildContext context) async {
    try {
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
    } on Exception catch (e) {
      doSomethingWithException(e);
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

  Future<String> uploadMediaToAppWrite(String uniqueID, String bucketID, String uri) async{
    String loadedUri = '';
    final appWriteStorage = Storage(updateAppWriteClient());
    await appWriteStorage.createFile(
      bucketId: bucketID,
      fileId: uniqueID,
      file: fileToInputFile(uri, uniqueID)
    ).then((response){
      loadedUri = 'https://cloud.appwrite.io/v1/storage/buckets/$bucketID/files/$uniqueID/view?project=$appWriteUserID&mode=admin';
    })
    .catchError((error) {
      debugPrint(error.response);
    });
    return loadedUri;
  }

  void editProfile() async{
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
          String currentID = fetchReduxDatabase().currentID;
          String nameText = nameController.text.trim();
          String usernameText = usernameController.text.trim();
          String imagePath = '';
          if(imageFilePath.value.isNotEmpty){
            imagePath = await uploadMediaToAppWrite(fetchReduxDatabase().currentID, storageBucketIDs['image'], imageFilePath.value);
          }else{
            imagePath = imageNetworkPath.value;
          }
          String stringified = jsonEncode({
            'userID': currentID,
            'name': nameText,
            'username': usernameText,
            'profilePicLink': imagePath,
            'bio': bioController.text.trim(),
            'birthDate': selectedBirthDate.toString()
          });
          var res = await dio.patch('$serverDomainAddress/users/editUserProfile', data: stringified);
          if(res.data.isNotEmpty){
            if(res.data['message'] == 'Successfully updated user profile'){
              UserDataClass currentUserProfileDataClass = fetchReduxDatabase().usersDatasNotifiers.value[currentID]!.notifier.value;
              UserDataClass updatedCurrentUserProfileDataClass = UserDataClass(
                currentID, nameText, usernameText, imagePath, currentUserProfileDataClass.dateJoined, 
                selectedBirthDate.toString(), bioController.text.trim(),
                currentUserProfileDataClass.mutedByCurrentID, currentUserProfileDataClass.blockedByCurrentID, 
                currentUserProfileDataClass.blocksCurrentID, currentUserProfileDataClass.private,
                currentUserProfileDataClass.requestedByCurrentID, currentUserProfileDataClass.requestsToCurrentID,
                currentUserProfileDataClass.verified, currentUserProfileDataClass.suspended, currentUserProfileDataClass.deleted
              );
              fetchReduxDatabase().usersDatasNotifiers.value[currentID]!.notifier.value = updatedCurrentUserProfileDataClass;
              Navigator.pop(context);
            }else{
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
        }
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: Center(
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding),
              child: ListView(
                children: <Widget>[
                  SizedBox(
                    height: defaultVerticalPadding
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Edit your profile', style: textFieldPageTitleTextStyle)
                    ]
                  ),
                  SizedBox(
                    height: titleToContentMargin,
                  ),
                  ValueListenableBuilder(
                    valueListenable: imageFilePath,
                    builder: (context, filePath, child){
                      return ValueListenableBuilder(
                        valueListenable: imageNetworkPath,
                        builder: (context, networkPath, child){
                          if(filePath.isNotEmpty){
                            return Column(
                              children: [
                                containerMargin(
                                  Container(
                                    width: getScreenWidth() * 0.35, height: getScreenWidth() * 0.35,
                                    decoration: BoxDecoration(
                                      border: Border.all(width: 2, color: Colors.white),
                                      borderRadius: BorderRadius.circular(100),
                                      image: DecorationImage(
                                        image: FileImage(
                                          File(filePath)
                                        ), fit: BoxFit.fill
                                      )
                                    ),
                                    child: Center(
                                      child: GestureDetector(
                                        onTap: (){
                                          if(mounted) imageFilePath.value = '';
                                        },
                                        child: const Icon(Icons.delete, size: 30)
                                      ),
                                    )
                                  ),
                                  EdgeInsets.only(top: getScreenHeight() * 0.0075, bottom: defaultPickedImageVerticalMargin)
                                )
                              ]
                            );
                          }else if(networkPath.isNotEmpty){
                            return Column(
                              children: [
                                containerMargin(
                                  Container(
                                    width: getScreenWidth() * 0.35, height: getScreenWidth() * 0.35,
                                    decoration: BoxDecoration(
                                      border: Border.all(width: 2, color: Colors.white),
                                      borderRadius: BorderRadius.circular(100),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          networkPath
                                        ), fit: BoxFit.fill
                                      )
                                    ),
                                    child: Center(
                                      child: GestureDetector(
                                        onTap: (){
                                          if(mounted) imageNetworkPath.value = '';
                                        },
                                        child: const Icon(Icons.delete, size: 30)
                                      ),
                                    )
                                  ),
                                  EdgeInsets.only(top: getScreenHeight() * 0.0075, bottom: defaultPickedImageVerticalMargin)
                                )
                              ]
                            );
                          }else{
                            return containerMargin(
                              Column(
                                children: [
                                  Container(
                                    width: getScreenWidth() * 0.35, height: getScreenWidth() * 0.35,
                                    decoration: BoxDecoration(
                                      border: Border.all(width: 2, color: Colors.white),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Center(
                                      child: GestureDetector(
                                        onTap: () => pickImage(),
                                        child: const Icon(Icons.add, size: 30)
                                      ),
                                    )
                                  )
                                ]
                              ),
                              EdgeInsets.only(top: getScreenHeight() * 0.0075, bottom: defaultPickedImageVerticalMargin)
                            );
                          }
                        }
                      );
                    }
                  ),
                  containerMargin(
                    textFieldWithDescription(
                      TextField(
                        controller: nameController,
                        decoration: generateProfileTextFieldDecoration('your name'),
                        maxLength: nameCharacterMaxLimit,
                      ),
                      'Name',
                      "Your name should be between 1 and $nameCharacterMaxLimit characters",
                    ), EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)),
                  containerMargin(
                    textFieldWithDescription(
                        TextField(
                        controller: usernameController,
                        decoration: generateProfileTextFieldDecoration('username'),
                        maxLength: usernameCharacterMaxLimit
                      ),
                      'Username',
                      "Your username should be between $usernameCharacterMinLimit and $usernameCharacterMaxLimit characters",
                    ),
                    EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                  ),
                  containerMargin(
                    textFieldWithDescription(
                      GestureDetector(
                        onTap: () => _selectBirthDate(context),
                        child: TextField(
                          controller: birthDateController,
                          decoration: generateProfileTextFieldDecoration('birth date'),
                          enabled: false,
                        ),
                      ),
                      'Birth Date',
                      ''
                    ),
                    EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                  ),
                  containerMargin(
                    textFieldWithDescription(
                      TextField(
                        controller: bioController,
                        decoration: generateBioTextFieldDecoration(),
                        maxLength: bioCharacterMaxLimit,
                        maxLines: 15,
                        minLines: 10,
                      ),
                      'Bio',
                      "Your bio is optional and should not exceed $bioCharacterMaxLimit characters",
                    ),
                    EdgeInsets.only(top: getScreenHeight() * 0.0075, bottom: defaultTextFieldVerticalMargin)
                  ),
                  SizedBox(
                    height: textFieldToButtonMargin
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: verifyNameFormat,
                        builder: (context, nameVerified, child) {
                          return ValueListenableBuilder(
                            valueListenable: verifyUsernameFormat,
                            builder: (context, usernameVerified, child) {
                              return ValueListenableBuilder(
                                valueListenable: verifyBirthDateFormat,
                                builder: (context, birthDateVerified, child) {
                                  return ValueListenableBuilder(
                                    valueListenable: isLoading,
                                    builder: (context, isLoadingValue, child) {
                                      return ValueListenableBuilder(
                                        valueListenable: imageFilePath,
                                        builder: (context, filePath, child) {
                                          return ValueListenableBuilder(
                                            valueListenable: imageNetworkPath,
                                            builder: (context, networkPath, child) {
                                              return CustomButton(
                                                width: defaultTextFieldButtonSize.width, height: defaultTextFieldButtonSize.height,
                                                buttonColor: Colors.red, buttonText: 'Continue', 
                                                onTapped: nameVerified && usernameVerified && birthDateVerified && (filePath.isNotEmpty || networkPath.isNotEmpty) && !isLoadingValue ? editProfile : null,
                                                setBorderRadius: true,
                                              );
                                            }
                                          );
                                        }
                                      );
                                    }
                                  );
                                }
                              );
                            }
                          );
                        }
                      )
                    ]
                  ),
                  SizedBox(
                    height: defaultVerticalPadding
                  )
                ],
              ),
            ),
            ValueListenableBuilder(
              valueListenable: isLoading,
              builder: (context, isLoadingValue, child) {
                return isLoadingValue ?
                  loadingSignWidget()
                : Container();
              } 
            )
          ]
        )
      ),
    );
  }
}
