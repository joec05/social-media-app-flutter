// ignore_for_file: library_prefixes, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:appwrite/appwrite.dart';
import 'package:custom_image_editor/EditImage.dart' as ImageEditor;
import 'package:custom_video_editor/VideoEditor.dart' as VideoEditor;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/SearchTagUsers.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/class/DisplayPostDataClass.dart';
import 'package:social_media_app/class/MediaDataClass.dart';
import 'package:social_media_app/custom/CustomButton.dart';
import 'package:social_media_app/custom/CustomTextEditingController.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/streams/PostDataStreamClass.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'class/PostClass.dart';
import 'class/WebsiteCardClass.dart';
import 'styles/AppStyles.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

var dio = Dio();

class WritePostWidget extends StatelessWidget {
  const WritePostWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _WritePostWidgetStateful();
  }
}

class _WritePostWidgetStateful extends StatefulWidget {
  const _WritePostWidgetStateful();

  @override
  State<_WritePostWidgetStateful> createState() => __WritePostWidgetStatefulState();
}

class __WritePostWidgetStatefulState extends State<_WritePostWidgetStateful> with LifecycleListenerMixin{
  CustomTextFieldEditingController postController = CustomTextFieldEditingController();
  ValueNotifier<List<MediaDatasClass>> mediasDatas = ValueNotifier([]);
  ValueNotifier<List<Widget>> mediasComponents = ValueNotifier([]);
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<bool> isListeningLink = ValueNotifier(false);
  ValueNotifier<bool> verifyPostFormat = ValueNotifier(false);
  ValueNotifier<List<String>> taggedUsersID = ValueNotifier([]);

  @override
  void initState(){
    super.initState();
    postController.addListener(() {
      if(mounted){
        String postText = postController.text;
        verifyPostFormat.value = postText.isNotEmpty && postText.length <= maxPostWordLimit;
      }
    });
  }

  @override void dispose(){
    super.dispose();
    isLoading.dispose();
    postController.dispose();
    mediasDatas.dispose();
    mediasComponents.dispose();
    verifyPostFormat.dispose();
    taggedUsersID.dispose();
    isListeningLink.dispose();
  }

  Future<void> pickImage(ImageSource source, {BuildContext? context}) async {
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
        if(mediasDatas.value.length < maxMediaCount){
          final XFile? pickedFile = await ImagePicker().pickImage(
            source: source,
            imageQuality: 100,
            maxWidth: 1000,
            maxHeight: 1000,
          );
          if(pickedFile != null && mediasDatas.value.length < maxMediaCount){
            String imageUrl = pickedFile.path;
            ui.Image imageDimension = await calculateImageFileDimension(imageUrl);
            Size scaledDimension = getSizeScale(imageDimension.width.toDouble(), imageDimension.height.toDouble());
            if(mounted){
              mediasDatas.value = [
                ...mediasDatas.value,
                MediaDatasClass(MediaType.image, imageUrl, null, '', MediaSourceType.file, null, scaledDimension)
              ];
              mediasComponents.value = [
                ...mediasComponents.value, mediaDataDraftPostComponentWidget(mediasDatas.value.last, scaledDimension)
              ];
            }
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  Future _pickVideo() async {
    bool permissionIsGranted = false;
    ph.Permission? permission;
    if(Platform.isAndroid){
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if(androidInfo.version.sdkInt <= 32){
        permission = ph.Permission.storage;
      }else{
        permission = ph.Permission.videos;
      }
    }
    permissionIsGranted = await permission!.isGranted;
    if(!permissionIsGranted){
      await permission.request();
      permissionIsGranted = await permission.isGranted;
    }

    if(permissionIsGranted){
      try {
        if(mediasDatas.value.length < maxMediaCount){
          final XFile? file = await ImagePicker().pickVideo(source: ImageSource.gallery);
          if (mounted && file != null && mediasDatas.value.length < maxMediaCount) {
            var playerController = VideoPlayerController.file(File(file.path));
            await playerController.initialize();
            Size scaledDimension = getSizeScale(playerController.value.size.width, playerController.value.size.height);
            if(mounted){
              mediasDatas.value = [...mediasDatas.value, MediaDatasClass(MediaType.video, file.path, playerController, '', MediaSourceType.file, null, scaledDimension)];
              mediasComponents.value = [
                ...mediasComponents.value, mediaDataDraftPostComponentWidget(mediasDatas.value.last, scaledDimension)
              ];
            }
          }else{
          }
        }
      } on Exception catch (e) {
        doSomethingWithException(e);
      }
    }
  }

  Future<void> editImage(File imageFile, int index) async {
    try {
      runDelay(()async {
        final fileResult = await Navigator.push(
          context,
          SliderRightToLeftRoute(
            page: ImageEditor.EditImageComponent(imageFile: imageFile)
          )
        );
        if (fileResult != null && fileResult is ImageEditor.FinishedImageData) {
          String imageUrl = fileResult.file.path; //file path of the newly updated image
          ui.Image imageDimension = await calculateImageFileDimension(imageUrl);
          Size scaledDimension = getSizeScale(imageDimension.width.toDouble(), imageDimension.height.toDouble());
          List<MediaDatasClass> mediasDatasList = [...mediasDatas.value];
          if(mounted){
            mediasDatasList[index] = MediaDatasClass(MediaType.image, imageUrl, null, '', MediaSourceType.file, null, scaledDimension);
            mediasDatas.value = [...mediasDatasList];
            List<Widget> mediasComponentsList = [...mediasComponents.value];
            mediasComponentsList[index] = mediaDataDraftPostComponentWidget(mediasDatas.value[index], scaledDimension);
            mediasComponents.value = [...mediasComponentsList];
          }
        }
      }, navigatorDelayTime); 
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<void> editVideo(String videoLink, int index) async {
    try {
      runDelay(()async {
        final updatedRes = await Navigator.push(
          context,
          SliderRightToLeftRoute(
            page: VideoEditor.EditVideoComponent(videoLink: videoLink)
          )
        );
        if(updatedRes != null && updatedRes is VideoEditor.FinishedVideoData){
          VideoPlayerController playerController = VideoPlayerController.file(File(updatedRes.url));
          await playerController.initialize();
          Size scaledDimension = getSizeScale(playerController.value.size.width, playerController.value.size.height);
          List<MediaDatasClass> mediasDatasList = [...mediasDatas.value];
          if(mounted){
            mediasDatasList[index] = MediaDatasClass(MediaType.video, updatedRes.url, playerController, '', MediaSourceType.file, null, scaledDimension);
            mediasDatas.value = [...mediasDatasList];
            List<Widget> mediasComponentsList = [...mediasComponents.value];
            mediasComponentsList[index] = mediaDataDraftPostComponentWidget(mediasDatas.value[index], scaledDimension);
            mediasComponents.value = [...mediasComponentsList];
          }
        }
      }, navigatorDelayTime);
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }
  
  Future<String> uploadImageToAppWrite(String bucketID, int index) async{
    String loadedUri = '';
    final appWriteStorage = Storage(updateAppWriteClient());
    String uniqueID = const Uuid().v4();
    await appWriteStorage.createFile(
      bucketId: bucketID,
      fileId: uniqueID,
      file: fileToInputFile(mediasDatas.value[index].url, uniqueID)
    ).then((response) async{
      loadedUri = 'https://cloud.appwrite.io/v1/storage/buckets/$bucketID/files/$uniqueID/view?project=$appWriteUserID&mode=admin';
      mediasDatas.value[index].storagePath = uniqueID;
    })
    .catchError((error) {
      debugPrint(error.response);
    });
    return loadedUri;
  }

  Future<String> uploadVideoToFirebase(BuildContext context, int index) async {
    String storageUrl = '';
    try {
      File mediaFilePath = File(mediasDatas.value[index].url);
      FirebaseStorage storage = FirebaseStorage.instance;
      String childDirectory = '/${appStateClass.currentID}/${const Uuid().v4()}';
      mediasDatas.value[index].storagePath = childDirectory;
      Reference ref = storage.ref('/videos').child(childDirectory);
      UploadTask uploadTask = ref.putFile(mediaFilePath, SettableMetadata(contentType: 'video/mp4'));
      var mediaUrl = await (await uploadTask).ref.getDownloadURL();
      storageUrl = mediaUrl.toString();
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
    return storageUrl;
  }

  void uploadPost() async{
    try {
      if(mounted){
        if(!isLoading.value && (postController.text.isNotEmpty || mediasDatas.value.isNotEmpty)){
          isLoading.value = true;
          String postID = const Uuid().v4();
          List<MediaDatasClass> updatedMediasDatas = [];
          for(int i = 0; i < mediasDatas.value.length; i++){
            MediaDatasClass mediaData = mediasDatas.value[i];
            String storageUrl = '';
            if(mediasDatas.value[i].mediaType == MediaType.image){
              storageUrl = await uploadImageToAppWrite(storageBucketIDs['image'], i);
            }else if(mediasDatas.value[i].mediaType == MediaType.video){
              mediaData.playerController!.pause();
              storageUrl = await uploadVideoToFirebase(context, i);
            }else if(mediasDatas.value[i].mediaType == MediaType.websiteCard){
              storageUrl = mediaData.url;
            }
            if(storageUrl.isNotEmpty){
              updatedMediasDatas.add(MediaDatasClass(
                mediaData.mediaType, storageUrl, mediaData.playerController, mediaData.storagePath, 
                MediaSourceType.network, mediaData.websiteCardData, mediaData.mediaSize
              ));
            }
          }
          
          List<Map<String, dynamic>> serverMediasDatas = [];
          for(int i = 0; i < updatedMediasDatas.length; i++){
            serverMediasDatas.add(updatedMediasDatas[i].toMap());
          }
          List<String> hashtags = (textDisplayHashtagRegex.allMatches(postController.text).map((match) => match.group(0)).map((str) => str!.substring(1).toLowerCase()).toSet().toList());
          String stringified = jsonEncode({
            'postId': postID,
            'content': postController.text,
            'sender': appStateClass.currentID,
            'mediasDatas': serverMediasDatas,
            'hashtags': hashtags.toSet().toList(),
            'taggedUsers': taggedUsersID.value.toSet().toList()
          });
          var res = await dio.post('$serverDomainAddress/users/uploadPost', data: stringified);
          if(res.data.isNotEmpty){
            if(res.data['message'] == 'Successfully uploaded the post'){
              PostClass postDataClass = PostClass(
                postID, 'post', postController.text, appStateClass.currentID, DateTime.now().toString(),
                updatedMediasDatas, 0, false, 0, false, 0, false 
              );
              updatePostData(postDataClass, context);
              PostDataStreamClass().emitData(
                PostDataStreamControllerClass(
                  DisplayPostDataClass(postDataClass.sender, postDataClass.postID),
                  appStateClass.currentID
                )
              );
              Navigator.pop(context);
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

  Widget mediaComponentIndex(mediaComponent, index){
    return Container(
      margin: EdgeInsets.only(top: mediaComponentMargin),
      child: Stack(
        children: [
          SizedBox(
            child: mediaComponent
          ),
          Positioned(
            top: 0, right: 0,
            child: Container(
              width: getScreenWidth() * 0.1,
              height: getScreenWidth() * 0.1,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: GestureDetector(
                onTap: (){
                  if(mounted){
                    List<Widget> mediasComponents2 = [...mediasComponents.value];
                    mediasComponents2.removeAt(index);
                    mediasComponents.value = mediasComponents2;
                    List<MediaDatasClass> mediasDatas2 = [...mediasDatas.value];
                    if(mediasDatas2[index].mediaType == MediaType.video){
                      mediasDatas2[index].playerController!.dispose();
                    }
                    mediasDatas2.removeAt(index);
                    mediasDatas.value = mediasDatas2;
                  }
                },
                child: const Icon(FontAwesomeIcons.trash, size: 17.5, color: Colors.black)
              )
            )
          ),
          Positioned(
            top: 0, right: getScreenWidth() * 0.125,
            child: Container(
              width: getScreenWidth() * 0.1,
              height: getScreenWidth() * 0.1,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: GestureDetector(
                onTap: (){
                  if(mediasDatas.value[index].mediaType == MediaType.image){
                    editImage(File(mediasDatas.value[index].url), index);
                  }else if(mediasDatas.value[index].mediaType == MediaType.video){
                    editVideo(mediasDatas.value[index].url, index);
                  }
                },
                child: const Icon(FontAwesomeIcons.pencil, size: 17.5, color: Colors.black)
              )
            )
          ),
        ],
      )
    );
  }

  void listenTextField(String value){
    if(isUserTagged(postController)){
      displayUsernamesToTag();
    }
  }

  void listenTextController(text) async{
    if(mounted){
      if(!isListeningLink.value && !isLoading.value && mediasDatas.value.length < maxMediaCount){
        isListeningLink.value = true;
        List textList = text.split(' ');
        for(int i = 0; i < textList.length; i++){
          if(textList[i].isNotEmpty){
            List lines = textList[i].split('\n');
            for(int j = 0; j < lines.length; j++){
              if(isLinkRegex.hasMatch(lines[j])){
                WebsiteCardClass linkPreview = await fetchLinkPreview(lines[j]);
                if(mounted){
                  if(linkPreview.title.isNotEmpty && mediasDatas.value.length < maxMediaCount){
                    mediasDatas.value = [...mediasDatas.value, MediaDatasClass(
                      MediaType.websiteCard, lines[j], null, '', MediaSourceType.network, linkPreview, null
                    )];
                    mediasComponents.value = [...mediasComponents.value, mediaDataDraftPostComponentWidget(mediasDatas.value.last, null)];
                    textList = text.split(' ');
                    textList[i] = textList[i].replaceFirst(lines[j], '');
                    postController.value = TextEditingValue(
                      text: textList.join(' '),
                      selection: TextSelection.fromPosition(
                        TextPosition(offset: textList.join(' ').length),
                      ),
                    );
                  }
                }
              }
            }
          }
        }
        if(mounted){
          isListeningLink.value = false;
        }
      }
    }
  }
  
  void displayUsernamesToTag(){
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SearchTagUsersWidget(onUserIsSelected: userIsTagged,);
      },
    );
  }

  void userIsTagged(List<String> usernames, List<String> userIDs){
    for(int i = 0; i < usernames.length; i++){
      String username = usernames[i];
      final int cursorPosition = postController.selection.start;
      String text = postController.text;
      String newText = '';
      if(i > 0){
        newText = '${text.substring(0, cursorPosition)}@$username ${text.substring(cursorPosition)}';
      }else{
        newText = '${text.substring(0, cursorPosition)}$username ${text.substring(cursorPosition)}';
      }
      if(mounted){
        postController.text = newText;
        postController.selection = TextSelection.fromPosition(
          TextPosition(offset: cursorPosition + username.length + 1)
        );
        taggedUsersID.value = [...taggedUsersID.value, ...userIDs];
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Upload Post'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (context, bool isLoadingValue, child){
              return ValueListenableBuilder<bool>(
                valueListenable: verifyPostFormat,
                builder: (context, bool postVerified, child){
                  return ValueListenableBuilder<List<MediaDatasClass>>(
                    valueListenable: mediasDatas,
                    builder: (context, List<MediaDatasClass> mediasDatasValue, child){
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: kToolbarHeight * 0.15, horizontal: getScreenWidth() * 0.025),
                        child: CustomButton(
                          width: getScreenWidth() * 0.25, height: kToolbarHeight, 
                          buttonColor: Colors.red, buttonText: 'Upload',
                          onTapped: !isLoadingValue && (mediasDatasValue.isNotEmpty || postVerified) ? () => uploadPost() : null,
                          setBorderRadius: true
                        )
                      );
                    }
                  );
                }
              );
            }
          )
        ]
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: ListView(
                  children: [
                    TextField(
                      controller: postController,
                      decoration: generatePostTextFieldDecoration('your post', FontAwesomeIcons.pencil),
                      minLines: postDraftTextFieldMinLines,
                      maxLines: postDraftTextFieldMaxLines,
                      maxLength: maxPostWordLimit,
                      onChanged: (value){
                        listenTextField(value);
                        listenTextController(value);
                      },
                      onEditingComplete: (){
                        listenTextController(postController.text);
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2),
                      child: ValueListenableBuilder<List>(
                        valueListenable: mediasComponents,
                        builder: ((context, mediasComponentsList, child) {
                          return Column(
                            children: [
                              for(int i = 0; i < mediasComponentsList.length; i++)
                              mediaComponentIndex(mediasComponentsList[i], i)
                            ],
                          );
                        }),
                      )
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white, width: 1)),
                ),
                child: ValueListenableBuilder<List>(
                  valueListenable: mediasComponents,
                  builder: (context, mediasComponentsList, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: (){pickImage(ImageSource.gallery, context: context);},
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.015, vertical: getScreenHeight() * 0.01),
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.photo, size: writePostIconSize,
                                  color: mediasComponents.value.length == maxMediaCount ? Colors.grey : Colors.white
                                ),
                              )
                            ),
                            GestureDetector(
                              onTap: (){pickImage(ImageSource.camera, context: context);},
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.015, vertical: getScreenHeight() * 0.01),
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.camera_alt_sharp, size: writePostIconSize,
                                  color: mediasComponents.value.length == maxMediaCount ? Colors.grey : Colors.white
                                ),
                              )
                            ),
                            GestureDetector(
                              onTap: () => _pickVideo(),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.015, vertical: getScreenHeight() * 0.01),
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.video_file_sharp, size: writePostIconSize,
                                  color: mediasComponents.value.length == maxMediaCount ? Colors.grey : Colors.white
                                ),
                              )
                            ),
                          ],
                        )
                      ]
                    );
                  }
                ) 
              )
            ]
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
    );
  }
}
