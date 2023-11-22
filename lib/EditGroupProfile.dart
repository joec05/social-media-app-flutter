import 'dart:convert';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/custom/CustomButton.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/socket/main.dart';
import 'package:uuid/uuid.dart';
import 'class/GroupProfileClass.dart';
import 'styles/AppStyles.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

var dio = Dio();

class EditGroupProfileWidget extends StatelessWidget {
  final String chatID;
  final GroupProfileClass groupProfileData;
  const EditGroupProfileWidget({super.key, required this.chatID, required this.groupProfileData});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return EditGroupProfileStateful(chatID: chatID, groupProfileData: groupProfileData);
  }
}

class EditGroupProfileStateful extends StatefulWidget {
  final String chatID;
  final GroupProfileClass groupProfileData;
  const EditGroupProfileStateful({super.key, required this.chatID, required this.groupProfileData});

  @override
  State<EditGroupProfileStateful> createState() => _EditGroupProfileStatefulState();
}

class _EditGroupProfileStatefulState extends State<EditGroupProfileStateful> with LifecycleListenerMixin{
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  ValueNotifier<String> imageFilePath = ValueNotifier('');
  ValueNotifier<String> imageNetworkPath = ValueNotifier('');
  ValueNotifier<bool> verifyNameFormat = ValueNotifier(false);
  final int nameCharacterMaxLimit = groupProfileInputMaxLimit['name'];
  final int descriptionCharacterMaxLimit = groupProfileInputMaxLimit['description'];
  late ValueNotifier<GroupProfileClass> groupProfile;
  late String chatID;

  @override
  void initState(){
    super.initState();
    chatID = widget.chatID;
    groupProfile = ValueNotifier(widget.groupProfileData);
    fetchUserProfileData();
    nameController.addListener(() {
      if(mounted){
        String nameText = nameController.text;
        verifyNameFormat.value = nameText.isNotEmpty && nameText.length <= nameCharacterMaxLimit;
      }
    });
    socket.on("send-leave-group-announcement-$chatID", ( data ) async{
      if(mounted && data != null){
        groupProfile.value = GroupProfileClass(
          groupProfile.value.name, groupProfile.value.profilePicLink, 
          groupProfile.value.description, List<String>.of(data['recipients'])
        );
      }
    });
    socket.on("send-add-users-to-group-announcement-$chatID", ( data ) async{
      if(mounted && data != null){
        groupProfile.value = GroupProfileClass(
          groupProfile.value.name, groupProfile.value.profilePicLink, 
          groupProfile.value.description, List<String>.of([...data['recipients'], ...data['addedUsersID']])
        );
      }
    });
  }

  @override void dispose(){
    super.dispose();
    isLoading.dispose();
    nameController.dispose();
    descriptionController.dispose();
    imageFilePath.dispose();
    imageNetworkPath.dispose();
    verifyNameFormat.dispose();
    groupProfile.dispose();
    socket.disconnect();
  }

  void fetchUserProfileData(){
    if(mounted){
      nameController.text = groupProfile.value.name;
      imageNetworkPath.value = groupProfile.value.profilePicLink;
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
        final XFile? pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
          maxWidth: 1000,
          maxHeight: 1000,
        );
        if(pickedFile != null && mounted){
          imageFilePath.value = pickedFile.path;
          imageNetworkPath.value = '';
        }
      } catch (e) {
        debugPrint(e.toString());
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

  void editGroupProfile() async{
    try {
      String messageID = const Uuid().v4();
      String senderName = fetchReduxDatabase().usersDatasNotifiers.value[fetchReduxDatabase().currentID]!.notifier.value.name;
      String content = '$senderName has edited the group profile';
      
      socket.emit("edit-group-profile-to-server", {
        'chatID': chatID,
        'messageID': messageID,
        'content': content,
        'type': 'edit_group_profile',
        'sender': fetchReduxDatabase().currentID,
        'recipients': groupProfile.value.recipients,
        'mediasDatas': [],
        'newData': {
          'name': nameController.text.trim(),
          'profilePicLink': imageFilePath.value.isEmpty ? imageNetworkPath.value : imageFilePath.value,
          'description': descriptionController.text.trim()
        }
      });
      Navigator.pop(context);
      String stringified = jsonEncode({
        'chatID': chatID,
        'messageID': messageID,
        'sender': fetchReduxDatabase().currentID,
        'recipients': groupProfile.value.recipients,
        'newData': {
          'name': nameController.text.trim(),
          'profilePicLink': imageFilePath.value.isEmpty ? imageNetworkPath.value : imageFilePath.value,
          'description': descriptionController.text.trim()
        }
      });
      var res = await dio.patch('$serverDomainAddress/users/editGroupProfileData', data: stringified);
      if(res.data.isNotEmpty){
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Group Profile'), 
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
                    ), EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                  ),
                  containerMargin(
                    textFieldWithDescription(
                      TextField(
                        controller: descriptionController,
                        decoration: generateProfileTextFieldDecoration('your description'),
                        maxLength: descriptionCharacterMaxLimit,
                      ),
                      'Description',
                      "Your name should be between 1 and $nameCharacterMaxLimit characters",
                    ), EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
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
                                        onTapped: nameVerified && (filePath.isNotEmpty || networkPath.isNotEmpty) && !isLoadingValue ? editGroupProfile : null,
                                        setBorderRadius: true,
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
