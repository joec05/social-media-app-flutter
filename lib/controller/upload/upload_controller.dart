import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:custom_image_editor/EditImage.dart' as image_editor;
import 'package:custom_video_editor/VideoEditor.dart' as video_editor;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

class UploadController {
  BuildContext context;
  CustomTextFieldEditingController textController = CustomTextFieldEditingController();
  ValueNotifier<List<MediaDatasClass>> mediasDatas = ValueNotifier([]);
  ValueNotifier<List<Widget>> mediasComponents = ValueNotifier([]);
  ValueNotifier<bool> isUploading = ValueNotifier(false);
  ValueNotifier<bool> isListeningLink = ValueNotifier(false);
  ValueNotifier<bool> verifyTextFormat = ValueNotifier(false);
  ValueNotifier<List<String>> taggedUsersID = ValueNotifier([]);

  UploadController(
    this.context
  );

  bool get mounted => context.mounted;
  List<String> splitHashtags() => (textDisplayHashtagRegex.allMatches(textController.text).map((match) => match.group(0)).map((str) => str!.substring(1).toLowerCase()).toSet().toList());
  
  void initializeController() {
    textController.addListener(() {
      if(mounted){
        String postText = textController.text;
        verifyTextFormat.value = postText.isNotEmpty && postText.length <= maxPostWordLimit;
      }
    });
  }

  void dispose(){
    isUploading.dispose();
    textController.dispose();
    mediasDatas.dispose();
    mediasComponents.dispose();
    verifyTextFormat.dispose();
    taggedUsersID.dispose();
    isListeningLink.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    bool permissionIsGranted = false;
    ph.Permission? permission;
    if(Platform.isAndroid){
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if(androidInfo.version.sdkInt <= 32){
        permission = ph.Permission.storage;
      }else{
        permission = ph.Permission.photos;
      }
    }else if(Platform.isIOS){
      permission = ph.Permission.photos;
    }
    permissionIsGranted = await permission!.isGranted;
    if(!permissionIsGranted){
      await permission.request();
      permissionIsGranted = await permission.isGranted;
    }

    if(permissionIsGranted && mounted){
      if(mediasDatas.value.length < maxMediaCount){
        final XFile? pickedFile = await ImagePicker().pickImage(
          source: source,
          imageQuality: 100,
          maxWidth: 1000,
          maxHeight: 1000,
        );
        if(mounted){
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
      }
    }
  }

  Future pickVideo() async {
    bool permissionIsGranted = false;
    ph.Permission? permission;
    if(Platform.isAndroid){
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if(androidInfo.version.sdkInt <= 32){
        permission = ph.Permission.storage;
      }else{
        permission = ph.Permission.videos;
      }
    }else if(Platform.isIOS){
      permission = ph.Permission.photos;
    }
    permissionIsGranted = await permission!.isGranted;
    if(!permissionIsGranted){
      await permission.request();
      permissionIsGranted = await permission.isGranted;
    }

    if(permissionIsGranted && mounted){
      if(mediasDatas.value.length < maxMediaCount){
        final XFile? file = await ImagePicker().pickVideo(source: ImageSource.gallery);
        if (file != null && mediasDatas.value.length < maxMediaCount) {
          var playerController = VideoPlayerController.file(File(file.path));
          await playerController.initialize();
          Size scaledDimension = getSizeScale(playerController.value.size.width, playerController.value.size.height);
          mediasDatas.value = [...mediasDatas.value, MediaDatasClass(MediaType.video, file.path, playerController, '', MediaSourceType.file, null, scaledDimension)];
          mediasComponents.value = [
            ...mediasComponents.value, mediaDataDraftPostComponentWidget(mediasDatas.value.last, scaledDimension)
          ];
        }
      }
    }
  }

  Future<void> editImage(File imageFile, int index) async {
    runDelay(() async {
      if(mounted){
        final fileResult = await Navigator.push(
          context,
          SliderRightToLeftRoute(
            page: image_editor.EditImageComponent(imageFile: imageFile)
          )
        );
        if (fileResult != null && fileResult is image_editor.FinishedImageData) {
          String imageUrl = fileResult.file.path; //file path of the newly updated image
          ui.Image imageDimension = await calculateImageFileDimension(imageUrl);
          Size scaledDimension = getSizeScale(imageDimension.width.toDouble(), imageDimension.height.toDouble());
          if(mounted){
            List<MediaDatasClass> mediasDatasList = [...mediasDatas.value];
            mediasDatasList[index] = MediaDatasClass(MediaType.image, imageUrl, null, '', MediaSourceType.file, null, scaledDimension);
            mediasDatas.value = [...mediasDatasList];
            List<Widget> mediasComponentsList = [...mediasComponents.value];
            mediasComponentsList[index] = mediaDataDraftPostComponentWidget(mediasDatas.value[index], scaledDimension);
            mediasComponents.value = [...mediasComponentsList];
          }
        }
      }
    }, navigatorDelayTime); 
  }

  Future<void> editVideo(String videoLink, int index) async {
    runDelay(() async {
      if(mounted){
        final updatedRes = await Navigator.push(
          context,
          SliderRightToLeftRoute(
            page: video_editor.EditVideoComponent(videoLink: videoLink)
          )
        );
        if(updatedRes != null && updatedRes is video_editor.FinishedVideoData){
          VideoPlayerController playerController = VideoPlayerController.file(File(updatedRes.url));
          await playerController.initialize();
          if(mounted){
            Size scaledDimension = getSizeScale(playerController.value.size.width, playerController.value.size.height);
            List<MediaDatasClass> mediasDatasList = [...mediasDatas.value];
            mediasDatasList[index] = MediaDatasClass(MediaType.video, updatedRes.url, playerController, '', MediaSourceType.file, null, scaledDimension);
            mediasDatas.value = [...mediasDatasList];
            List<Widget> mediasComponentsList = [...mediasComponents.value];
            mediasComponentsList[index] = mediaDataDraftPostComponentWidget(mediasDatas.value[index], scaledDimension);
            mediasComponents.value = [...mediasComponentsList];
          }
        }
      }
    }, navigatorDelayTime);
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
                  if(mounted){
                    if(mediasDatas.value[index].mediaType == MediaType.image){
                      editImage(File(mediasDatas.value[index].url), index);
                    }else if(mediasDatas.value[index].mediaType == MediaType.video){
                      editVideo(mediasDatas.value[index].url, index);
                    }
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
    if(isUserTagged(textController)){
      displayUsernamesToTag();
    }
  }

  void listenTextController(text) async{
    if(mounted){
      if(!isListeningLink.value && !isUploading.value && mediasDatas.value.length < maxMediaCount){
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
                    textController.value = TextEditingValue(
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
      final int cursorPosition = textController.selection.start;
      if(mounted){
        String text = textController.text;
        String newText = '';
        if(i > 0){
          newText = '${text.substring(0, cursorPosition)}@$username ${text.substring(cursorPosition)}';
        }else{
          newText = '${text.substring(0, cursorPosition)}$username ${text.substring(cursorPosition)}';
        }
        textController.text = newText;
        textController.selection = TextSelection.fromPosition(
          TextPosition(offset: cursorPosition + username.length + 1)
        );
        if(mounted){
          taggedUsersID.value = [...taggedUsersID.value, ...userIDs];
        }
      }
    }
  }
  
  void initializeEditedPost(
    String postContent,
    List<MediaDatasClass> postMediaDatas
  ) async{
    if(mounted){
      isUploading.value = true;
      textController.text = postContent;
      for(int i = 0; i < postMediaDatas.length; i++){
        if(mounted){
          MediaDatasClass e = postMediaDatas[i];
          if(e.mediaType == MediaType.image){
            String filePath = await downloadAndSaveImage(e.url, const Uuid().v4());
            MediaDatasClass updatedMediaData = MediaDatasClass(
              e.mediaType, filePath, e.playerController, e.storagePath, MediaSourceType.file, e.websiteCardData, e.mediaSize
            );
            if(mounted){
              mediasDatas.value = [...mediasDatas.value, updatedMediaData];
              mediasComponents.value = [
                ...mediasComponents.value,
                mediaDataDraftPostComponentWidget(updatedMediaData, e.mediaSize)
              ];
            }
          }else if(e.mediaType == MediaType.video){
            MediaDatasClass updatedMediaData = MediaDatasClass(
              e.mediaType, e.url, e.playerController, e.storagePath, MediaSourceType.network, e.websiteCardData, e.mediaSize
            );
            if(mounted){
              mediasDatas.value = [...mediasDatas.value, updatedMediaData];
              mediasComponents.value = [
                ...mediasComponents.value,
                mediaDataDraftPostComponentWidget(updatedMediaData, e.mediaSize)
              ];
            }
          }else if(e.mediaType == MediaType.websiteCard){
            if(mounted){
              mediasDatas.value = [...mediasDatas.value, e];
              mediasComponents.value = [...mediasComponents.value, CustomWebsiteCardComponent(
                websiteCardData: e.websiteCardData!, websiteCardState: WebsiteCardState.draft
              )];
            }
          }
        }
      }
      if(mounted){
        isUploading.value = false;
      }
    }
  }

  void uploadPost() async{
    if(mounted) {
      try {
        if(!isUploading.value && (textController.text.isNotEmpty || mediasDatas.value.isNotEmpty)){
          isUploading.value = true;
          String postID = const Uuid().v4();
          List<MediaDatasClass> updatedMediasDatas = [];
          for(int i = 0; i < mediasDatas.value.length; i++){
            if(mounted){
              MediaDatasClass mediaData = mediasDatas.value[i];
              String storageUrl = '';
              if(mediasDatas.value[i].mediaType == MediaType.image){
                storageUrl = await cloudController.uploadImageToAppWrite(
                  context,
                  mediasDatas.value[i].url
                );
              }else if(mediasDatas.value[i].mediaType == MediaType.video){
                mediaData.playerController!.pause();
                storageUrl = await cloudController.uploadVideoToFirebase(
                  context,
                  mediasDatas.value[i].url                  
                );
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
          }
          if(mounted){
            List<Map<String, dynamic>> serverMediasDatas = [];
            for(int i = 0; i < updatedMediasDatas.length; i++){
              serverMediasDatas.add(updatedMediasDatas[i].toMap());
            }
            List<String> hashtags = splitHashtags();
            dynamic res = await fetchDataRepo.fetchData(
              context, 
              RequestPost.uploadPost, 
              {
                'postId': postID,
                'text': textController.text,
                'sender': appStateClass.currentID,
                'mediasDatas': serverMediasDatas,
                'hashtags': hashtags.toSet().toList(),
                'taggedUsers': taggedUsersID.value.toSet().toList()
              }
            );
            if(mounted){
              isUploading.value = false;
              if(res != null){
                PostClass postDataClass = PostClass(
                  postID, 'post', textController.text, appStateClass.currentID, DateTime.now().toString(),
                  updatedMediasDatas, 0, false, 0, false, 0, false 
                );
                updatePostData(postDataClass);
                PostDataStreamClass().emitData(
                  PostDataStreamControllerClass(
                    DisplayPostDataClass(postDataClass.sender, postDataClass.postID),
                    appStateClass.currentID
                  )
                );
                Navigator.pop(context);
              }
            }
          }
        }
      } catch (_) {
        if(mounted) {
          isUploading.value = false;
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            tErr.unknown
          );
        }
      }
    }
  }
  
  void editPost(PostClass postData) async{
    if(mounted) {
      try {
        if(!isUploading.value && (textController.text.isNotEmpty || mediasDatas.value.isNotEmpty)){
          isUploading.value = true;
          String postID = postData.postID;
          PostClass previousPostData = appStateClass.postsNotifiers.value[postData.sender]![postID]!.notifier.value;
          List<MediaDatasClass> updatedMediasDatas = [];
          for(int i = 0; i < mediasDatas.value.length; i++){
            if(mounted){
              MediaDatasClass mediaData = mediasDatas.value[i];
              String storageUrl = '';
              if(mediasDatas.value[i].mediaType == MediaType.image){
                storageUrl = await cloudController.uploadImageToAppWrite(
                  context,
                  mediasDatas.value[i].url
                );
              }else if(mediasDatas.value[i].mediaType == MediaType.video){
                mediaData.playerController!.pause();
                storageUrl = await cloudController.uploadVideoToFirebase(
                  context,
                  mediasDatas.value[i].url                  
                );
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
          }
          if(mounted){
            List<Map<String, dynamic>> serverMediasDatas = [];
            for(int i = 0; i < updatedMediasDatas.length; i++){
              serverMediasDatas.add(updatedMediasDatas[i].toMap());
            }
            List<String> hashtags = splitHashtags();
            dynamic res = await fetchDataRepo.fetchData(
              context, 
              RequestPatch.editPost, 
              {
                'postId': postID,
                'text': textController.text,
                'sender': appStateClass.currentID,
                'mediasDatas': serverMediasDatas,
                'hashtags': hashtags.toSet().toList(),
                'taggedUsers': taggedUsersID.value.toSet().toList(),
              }
            );
            if(mounted) {
              isUploading.value = false;
              if(res != null) {
                PostClass postDataClass = PostClass(
                  postID, 'post', textController.text, appStateClass.currentID, previousPostData.uploadTime, updatedMediasDatas, 
                  previousPostData.likesCount, previousPostData.likedByCurrentID, previousPostData.bookmarksCount, 
                  previousPostData.bookmarkedByCurrentID, previousPostData.commentsCount, previousPostData.deleted
                );
                updatePostData(postDataClass);
                Navigator.pop(context);
              }
            }
          }
        }
      } catch (_) {
        if(mounted) {
          isUploading.value = false;
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            tErr.unknown
          );
        }
      }
    }
  }

  void uploadComment(
    String parentPostID,
    String parentPostSender,
    String parentPostType
  ) async{
    if(mounted) {
      try {
        if(!isUploading.value && (textController.text.isNotEmpty || mediasDatas.value.isNotEmpty)){
          isUploading.value = true;
          String commentID = const Uuid().v4();
          List<MediaDatasClass> updatedMediasDatas = [];
          for(int i = 0; i < mediasDatas.value.length; i++){
            if(mounted){
              MediaDatasClass mediaData = mediasDatas.value[i];
              String storageUrl = '';
              if(mediasDatas.value[i].mediaType == MediaType.image){
                storageUrl = await cloudController.uploadImageToAppWrite(
                  context,
                  mediasDatas.value[i].url
                );
              }else if(mediasDatas.value[i].mediaType == MediaType.video){
                mediaData.playerController!.pause();
                storageUrl = await cloudController.uploadVideoToFirebase(
                  context,
                  mediasDatas.value[i].url                  
                );
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
          }
          if(mounted){
            List<Map<String, dynamic>> serverMediasDatas = [];
            for(int i = 0; i < updatedMediasDatas.length; i++){
              serverMediasDatas.add(updatedMediasDatas[i].toMap());
            }
            List<String> hashtags = splitHashtags();
            dynamic res = await fetchDataRepo.fetchData(
              context, 
              RequestPost.uploadComment, 
              {
                'commentID': commentID,
                'text': textController.text,
                'sender': appStateClass.currentID,
                'mediasDatas': serverMediasDatas,
                'parentPostID': parentPostID,
                'parentPostSender': parentPostSender,
                'parentPostType': parentPostType,
                'hashtags': hashtags.toSet().toList(),
                'taggedUsers': taggedUsersID.value.toSet().toList()
              }
            );
            if(mounted) {
              isUploading.value = false;
              if(res != null) {
                CommentClass commentDataClass = CommentClass(
                  commentID, 'comment', textController.text, appStateClass.currentID, DateTime.now().toString(),
                  updatedMediasDatas, 0, false, 0, false, 0, parentPostType, parentPostID, parentPostSender, false 
                );
                updateCommentData(commentDataClass);
                if(parentPostType == 'post'){
                  PostClass parentPostData = appStateClass.postsNotifiers.value[parentPostSender]![parentPostID]!.notifier.value;
                  appStateClass.postsNotifiers.value[parentPostData.sender]![parentPostData.postID]!.notifier.value = PostClass(
                    parentPostData.postID, parentPostData.type, parentPostData.content, parentPostData.sender, parentPostData.uploadTime, 
                    parentPostData.mediasDatas, parentPostData.likesCount, parentPostData.likedByCurrentID, 
                    parentPostData.bookmarksCount, parentPostData.bookmarkedByCurrentID, parentPostData.commentsCount + 1, parentPostData.deleted
                  );
                }else{
                  CommentClass parentCommentData = appStateClass.commentsNotifiers.value[parentPostSender]![parentPostID]!.notifier.value;
                  appStateClass.commentsNotifiers.value[parentCommentData.sender]![parentCommentData.commentID]!.notifier.value = CommentClass(
                    parentCommentData.commentID, parentCommentData.type, parentCommentData.content, 
                    parentCommentData.sender, parentCommentData.uploadTime, 
                    parentCommentData.mediasDatas, parentCommentData.likesCount, parentCommentData.likedByCurrentID, 
                    parentCommentData.bookmarksCount, parentCommentData.bookmarkedByCurrentID, parentCommentData.commentsCount + 1, 
                    parentCommentData.parentPostType, parentCommentData.parentPostID, 
                    parentCommentData.parentPostSender, parentCommentData.deleted
                  );
                }
                CommentDataStreamClass().emitData(
                  CommentDataStreamControllerClass(
                    DisplayCommentDataClass(commentDataClass.sender, commentDataClass.commentID),
                    appStateClass.currentID
                  )
                );
                CommentDataStreamClass().emitData(
                  CommentDataStreamControllerClass(
                    DisplayCommentDataClass(commentDataClass.sender, commentDataClass.commentID),
                    commentDataClass.parentPostID
                  )
                );
                Navigator.pop(context, commentID);
              }
            }
          }
        }
      } catch (_) {
        if(mounted) {
          isUploading.value = false;
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            tErr.unknown
          );
        }
      }
    }
  }

  void editComment(CommentClass commentData) async{
    if(mounted) {
      try {
        if(!isUploading.value && (textController.text.isNotEmpty || mediasDatas.value.isNotEmpty)) {
          isUploading.value = true;
          String commentID = commentData.commentID;
          CommentClass previousCommentData = appStateClass.commentsNotifiers.value[commentData.sender]![commentID]!.notifier.value;
          List<MediaDatasClass> updatedMediasDatas = [];
          for(int i = 0; i < mediasDatas.value.length; i++){
            if(mounted){
              MediaDatasClass mediaData = mediasDatas.value[i];
              String storageUrl = '';
              if(mediasDatas.value[i].mediaType == MediaType.image){
                storageUrl = await cloudController.uploadImageToAppWrite(
                  context,
                  mediasDatas.value[i].url
                );
              }else if(mediasDatas.value[i].mediaType == MediaType.video){
                mediaData.playerController!.pause();
                storageUrl = await cloudController.uploadVideoToFirebase(
                  context,
                  mediasDatas.value[i].url                  
                );
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
          }
          if(mounted){
            List<Map<String, dynamic>> serverMediasDatas = [];
            for(int i = 0; i < updatedMediasDatas.length; i++){
              serverMediasDatas.add(updatedMediasDatas[i].toMap());
            }
            List<String> hashtags = splitHashtags();
            dynamic res = await fetchDataRepo.fetchData(
              context, 
              RequestPatch.editComment, 
              {
                'commentID': commentID,
                'content': textController.text,
                'sender': appStateClass.currentID,
                'mediasDatas': serverMediasDatas,
                'parentPostID': previousCommentData.parentPostID,
                'parentPostSender': previousCommentData.parentPostSender,
                'parentPostType': previousCommentData.parentPostType,
                'hashtags': hashtags.toSet().toList(),
                'taggedUsers': taggedUsersID.value.toSet().toList()
              }
            );
            if(mounted){
              isUploading.value = false;
              if(res != null){
                CommentClass commentDataClass = CommentClass(
                  commentID, 'comment', textController.text, appStateClass.currentID, previousCommentData.uploadTime,
                  updatedMediasDatas, previousCommentData.likesCount, previousCommentData.likedByCurrentID, previousCommentData.bookmarksCount,
                  previousCommentData.bookmarkedByCurrentID, previousCommentData.commentsCount, previousCommentData.parentPostType, 
                  previousCommentData.parentPostID, previousCommentData.parentPostSender, previousCommentData.deleted
                );
                updateCommentData(commentDataClass);
                Navigator.pop(context, commentID);
              }
            }
          }
        }
      } catch (_) {
        if(mounted) {
          isUploading.value = false;
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            tErr.unknown
          );
        }
      }
    }
  }

  void sendPrivateMessage(
    String? chatID,
    String recipient
  ) async{
    if(mounted) {
      try {
        if(!isUploading.value) {
          isUploading.value = true;
          String messageID = const Uuid().v4();
          String? newChatID;
          if(chatID == null){
            newChatID = const Uuid().v4();
          }
          List<MediaDatasClass> updatedMediasDatas = [];
          for(int i = 0; i < mediasDatas.value.length; i++){
            if(mounted){
              MediaDatasClass mediaData = mediasDatas.value[i];
              String storageUrl = '';
              if(mediasDatas.value[i].mediaType == MediaType.image){
                storageUrl = await cloudController.uploadImageToAppWrite(
                  context,
                  mediasDatas.value[i].url
                );
              }else if(mediasDatas.value[i].mediaType == MediaType.video){
                mediaData.playerController!.pause();
                storageUrl = await cloudController.uploadVideoToFirebase(
                  context,
                  mediasDatas.value[i].url                  
                );
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
          }
          if(mounted) {
            List<Map<String, dynamic>> serverMediasDatas = [];
            for(int i = 0; i < updatedMediasDatas.length; i++){
              serverMediasDatas.add(updatedMediasDatas[i].toMap());
            }
            socket.emit("send-private-message-to-server", {
              'chatID': chatID ?? newChatID,
              'messageID': messageID,
              'type': 'message',
              'content': textController.text,
              'sender': appStateClass.currentID,
              'recipient': recipient,
              'mediasDatas': serverMediasDatas,
            });
            textController.text = '';
            mediasDatas.value = [];
            mediasComponents.value = [];
            dynamic res = await fetchDataRepo.fetchData(
              context, 
              RequestPost.sendPrivateMessage, 
              {
                'chatID': chatID,
                'newChatID': newChatID,
                'messageID': messageID,
                'content': textController.text,
                'sender': appStateClass.currentID,
                'recipient': recipient,
                'mediasDatas': serverMediasDatas,
              }
            );
            if(mounted) {
              isUploading.value = false;
              if(res != null) {
                chatID ??= newChatID;
              }
            }
          }
        }
      } catch (_) {
        if(mounted) {
          isUploading.value = false;
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            tErr.unknown
          );
        }
      }
    }
  }

  void sendGroupMessage(
    GroupChatController chatController
  ) async{
    if(mounted) {
      try {
        if(!isUploading.value) {
          isUploading.value = true;
          String messageID = const Uuid().v4();
          List<MediaDatasClass> updatedMediasDatas = [];
          for(int i = 0; i < mediasDatas.value.length; i++){
            if(mounted){
              MediaDatasClass mediaData = mediasDatas.value[i];
              String storageUrl = '';
              if(mediasDatas.value[i].mediaType == MediaType.image){
                storageUrl = await cloudController.uploadImageToAppWrite(
                  context,
                  mediasDatas.value[i].url
                );
              }else if(mediasDatas.value[i].mediaType == MediaType.video){
                mediaData.playerController!.pause();
                storageUrl = await cloudController.uploadVideoToFirebase(
                  context,
                  mediasDatas.value[i].url                  
                );
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
          }
          if(mounted) {
            List<Map<String, dynamic>> serverMediasDatas = [];
            for(int i = 0; i < updatedMediasDatas.length; i++){
              serverMediasDatas.add(updatedMediasDatas[i].toMap());
            }
            socket.emit("send-group-message-to-server", {
              'chatID': chatController.chatID.value ?? chatController.newChatID.value,
              'messageID': messageID,
              'content': textController.text,
              'sender': appStateClass.currentID,
              'senderData': appStateClass.usersDataNotifiers.value[appStateClass.currentID]!.notifier.value.toMap(),
              'recipients': chatController.recipientsList,
              'mediasDatas': serverMediasDatas,
              'type': 'message'
            });
            textController.text = '';
            mediasDatas.value = [];
            mediasComponents.value = [];
            dynamic res = await fetchDataRepo.fetchData(
              context, 
              RequestPost.sendGroupMessage, 
              {
                'chatID': chatController.chatID.value,
                'newChatID': chatController.newChatID.value,
                'messageID': messageID,
                'content': textController.text,
                'sender': appStateClass.currentID,
                'recipients': chatController.recipientsList,
                'mediasDatas': serverMediasDatas,
              }
            );
            if(mounted) {
              isUploading.value = false;
              if(res != null) {
                if(chatController.chatID.value == null){
                  chatController.chatID.value = chatController.newChatID.value;
                  chatController.newChatID.value = null;
                  chatController.groupProfile.value = GroupProfileClass(
                    'Group ${chatController.chatID}', 
                    chatController.groupProfile.value.profilePicLink, 
                    '', chatController.recipientsList!
                  );
                }
              }
            }
          }
        }
      } catch (_) {
        if(mounted) {
          isUploading.value = false;
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            tErr.unknown
          );
        }
      }
    }
  }
}