import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ExploreController {
  BuildContext context;
  TextEditingController searchedController = TextEditingController();
  ValueNotifier<List<HashtagClass>> hashtags = ValueNotifier([]);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<List<DisplayPostDataClass>> posts = ValueNotifier([]);
  ValueNotifier<bool> verifySearchedFormat = ValueNotifier(false);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  final ScrollController scrollController = ScrollController();
  final exploreDataLimit = 10;

  ExploreController(
    this.context
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchExploreData(), actionDelayTime);
    searchedController.addListener(() {
      if(mounted){
        verifySearchedFormat.value = searchedController.text.isNotEmpty;
      }
    });
    scrollController.addListener(() {
      if(mounted){
        if(scrollController.position.pixels > animateToTopMinHeight){
          if(!displayFloatingBtn.value){
            displayFloatingBtn.value = true;
          }
        }else{
          if(displayFloatingBtn.value){
            displayFloatingBtn.value = false;
          }
        }
      }
    });
  }

  void dispose(){
    searchedController.dispose();
    hashtags.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchExploreData() async{
    try {
      String stringified = jsonEncode({
        'currentID': appStateClass.currentID,
        'paginationLimit': exploreDataLimit,
      });
      if(mounted){
        users.value = [];
        hashtags.value = [];
        posts.value = [];
      }
      var res = await dio.get('$serverDomainAddress/users/fetchTopData', data: stringified);
      if(res.data.isNotEmpty){
        List postsData = res.data['postsData'];
        List usersProfileDatasList = res.data['usersProfileData'];
        List usersSocialsDatasList = res.data['usersSocialsData'];
        List hashtagsData = res.data['hashtagsData'];
        for(int i = 0; i < postsData.length; i++){
          Map postData = postsData[i];
          List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
          List<MediaDatasClass> newMediasDatas = [];
          newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
          PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
          if(mounted){
            updatePostData(postDataClass);
            posts.value = [...posts.value, DisplayPostDataClass(postData['sender'], postData['post_id'])];
          } 
        }
        for(int i = 0; i < usersProfileDatasList.length; i++){
          Map userProfileData = usersProfileDatasList[i];
          UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
          UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
          if(mounted){
            updateUserData(userDataClass);
            updateUserSocials(userDataClass, userSocialClass);
            users.value = [userProfileData['user_id'], ...users.value];
          }
        }
        for(int i = 0; i < hashtagsData.length; i++){
          Map hashtagData = hashtagsData[i];
          if(mounted){
            hashtags.value = [...hashtags.value, HashtagClass(hashtagData['hashtag'], hashtagData['hashtag_count'])];
          }
        }
        loadingState.value = LoadingState.loaded;
      }
    } on Exception catch (e) {
      
    }
  }
}