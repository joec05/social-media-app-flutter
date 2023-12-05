// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/custom/CustomButton.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import 'MainPage.dart';
import 'styles/AppStyles.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

var dio = Dio();

class CompleteSignUpProfileStateless extends StatelessWidget {
  const CompleteSignUpProfileStateless({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompleteSignUpProfileStateful();
  }
}

class CompleteSignUpProfileStateful extends StatefulWidget {
  const CompleteSignUpProfileStateful({super.key});

  @override
  State<CompleteSignUpProfileStateful> createState() => _CompleteSignUpProfileStatefulState();
}

class _CompleteSignUpProfileStatefulState extends State<CompleteSignUpProfileStateful> with LifecycleListenerMixin{
  ValueNotifier<String> imageFilePath = ValueNotifier('');
  TextEditingController bioController = TextEditingController();
  ValueNotifier<bool> verifyBioFormat = ValueNotifier(false);
  final int bioCharacterMaxLimit = profileInputMaxLimit['bio'];
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  @override
  void initState(){
    super.initState();
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
    imageFilePath.dispose();
    bioController.dispose();
    verifyBioFormat.dispose();
    isLoading.dispose();
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
  
  void completeSignUpProfile() async{
    try {
      if(mounted){
        if(!isLoading.value){
          isLoading.value = true;
          String uploadProfilePic = await uploadMediaToAppWrite(appStateClass.currentID, storageBucketIDs['image'], imageFilePath.value);
          String stringified = jsonEncode({
            'userId': appStateClass.currentID,
            'profilePicLink': uploadProfilePic,
            'bio': bioController.text.trim(),
          });
          var res = await dio.post('$serverDomainAddress/users/completeSignUpProfile', data: stringified);
          if(res.data.isNotEmpty){
            if(res.data['message'] == 'Successfully updated your account'){
              appStateClass.usersDataNotifiers.value[appStateClass.currentID]!.notifier.value.profilePicLink = uploadProfilePic;
              runDelay(() => Navigator.pushAndRemoveUntil(
                context,
                SliderRightToLeftRoute(
                  page: const MainPageWidget()
                ),
                (Route<dynamic> route) => false
              ), navigatorDelayTime);
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
        }
      } catch(e) {
        debugPrint('Failed to pick image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Complete Sign Up'), 
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
                    height: titleToContentMargin,
                  ),
                  Center(
                    child: containerMargin(
                      Text('Select your profile picture', style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.w500)),
                      EdgeInsets.only(top: defaultPickedImageVerticalMargin, bottom: getScreenHeight() * 0.0075)
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: imageFilePath,
                    builder: (context, filePath, child){
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
                  ),
                  SizedBox(
                    height: getScreenHeight() * 0.025
                  ),
                  Center(
                    child: containerMargin(
                      Text('Complete your bio (optional)', style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.w500)),
                      EdgeInsets.only(top: defaultPickedImageVerticalMargin, bottom: getScreenHeight() * 0.0075)
                    ),
                  ),
                  containerMargin(
                    textFieldWithDescription(
                      TextField(
                        controller: bioController,
                        decoration: generateBioTextFieldDecoration('bio', Icons.person),
                        maxLength: bioCharacterMaxLimit,
                        maxLines: 5,
                        minLines: 1,
                      ),
                      'Bio',
                      "Your bio is optional and should not exceed $bioCharacterMaxLimit characters",
                    ),
                    EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                  ),
                  SizedBox(
                    height: textFieldToButtonMargin
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable: imageFilePath,
                        builder: (context, String filePath, child) {
                          return ValueListenableBuilder(
                            valueListenable: isLoading,
                            builder: (context, isLoadingValue, child) {
                              return CustomButton(
                                width: defaultTextFieldButtonSize.width, height: defaultTextFieldButtonSize.height,
                                buttonColor: Colors.red, buttonText: 'Continue', 
                                onTapped: filePath.isNotEmpty && !isLoadingValue ? () => completeSignUpProfile() : null,
                                setBorderRadius: true,
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
