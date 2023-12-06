import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:social_media_app/Searched.dart';
import 'package:social_media_app/class/DisplayPostDataClass.dart';
import 'package:social_media_app/class/HashtagClass.dart';
import 'package:social_media_app/class/MediaDataClass.dart';
import 'package:social_media_app/class/PostClass.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/custom/CustomHashtagWidget.dart';
import 'package:social_media_app/custom/CustomPostWidget.dart';
import 'package:social_media_app/custom/CustomUserDataWidget.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';

var dio = Dio();

class ExploreWidget extends StatelessWidget {
  const ExploreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ExploreWidgetStateful();
  }
}

class _ExploreWidgetStateful extends StatefulWidget {
  const _ExploreWidgetStateful();

  @override
  State<_ExploreWidgetStateful> createState() => __ExploreWidgetStatefulState();
}

class __ExploreWidgetStatefulState extends State<_ExploreWidgetStateful> with AutomaticKeepAliveClientMixin, LifecycleListenerMixin {
  TextEditingController searchedController = TextEditingController();
  ValueNotifier<List<HashtagClass>> hashtags = ValueNotifier([]);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<List<DisplayPostDataClass>> posts = ValueNotifier([]);
  ValueNotifier<bool> verifySearchedFormat = ValueNotifier(false);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ScrollController _scrollController = ScrollController();
  final exploreDataLimit = 10;

  @override
  void initState(){
    super.initState();
    runDelay(() async => fetchExploreData(), actionDelayTime);
    searchedController.addListener(() {
      if(mounted){
        verifySearchedFormat.value = searchedController.text.isNotEmpty;
      }
    });
    _scrollController.addListener(() {
      if(mounted){
        if(_scrollController.position.pixels > animateToTopMinHeight){
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

  @override void dispose(){
    super.dispose();
    searchedController.dispose();
    hashtags.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchExploreData() async{
    isLoading.value = true;
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
            updatePostData(postDataClass, context);
            posts.value = [...posts.value, DisplayPostDataClass(postData['sender'], postData['post_id'])];
          } 
        }
        for(int i = 0; i < usersProfileDatasList.length; i++){
          Map userProfileData = usersProfileDatasList[i];
          UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
          UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
          if(mounted){
            updateUserData(userDataClass, context);
            updateUserSocials(userDataClass, userSocialClass, context);
            users.value = [userProfileData['user_id'], ...users.value];
          }
        }
        for(int i = 0; i < hashtagsData.length; i++){
          Map hashtagData = hashtagsData[i];
          if(mounted){
            hashtags.value = [...hashtags.value, HashtagClass(hashtagData['hashtag'], hashtagData['hashtag_count'])];
          }
        }
        isLoading.value = false;
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => fetchExploreData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: verifySearchedFormat,
              builder: (context, bool searchedVerified, child){
                return SizedBox(
                  width: getScreenWidth(),
                  height: getScreenHeight() * 0.075,
                  child: TextField(
                    controller: searchedController,
                    decoration: generateSearchTextFieldDecoration(
                      'your interests', Icons.search,
                      searchedVerified ? (){
                        runDelay(() => Navigator.push(
                          context,
                          SliderRightToLeftRoute(
                            page: SearchedWidget(searchedText: searchedController.text)
                          )
                        ), navigatorDelayTime);
                      } : null
                    ),
                  )
                );
              }
            ),
            Column(
              children: [
                SizedBox(height: defaultVerticalPadding * 1.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: defaultHorizontalPadding / 2),
                    Text('Popular tags', style: TextStyle(fontSize: defaultTextFontSize * 1.1, fontWeight: FontWeight.bold))
                  ]
                ),
                SizedBox(height: defaultVerticalPadding * 0.25),
              ]
            ),
            ValueListenableBuilder(
              valueListenable: isLoading,
              builder: ((context, isLoadingValue, child) {
                return ValueListenableBuilder(
                  valueListenable: hashtags, 
                  builder: (context, hashtagsValue, child){
                    if(!isLoadingValue){
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: hashtagsValue.length,
                        itemBuilder: (context, index) {
                          return CustomHashtagDataWidget(
                            hashtagData: hashtagsValue[index],
                            key: UniqueKey(), 
                            skeletonMode: false
                          );
                        }
                      );
                    }else{
                      return Skeletonizer(
                        enabled: true,
                        child: ListView.builder(
                          itemCount: exploreDataLimit,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return CustomHashtagDataWidget(
                              hashtagData: HashtagClass.getFakeData(), 
                              key: UniqueKey(), 
                              skeletonMode: true
                            );
                          }
                        )
                      );
                    }
                  }
                );
              })
            ),
            Column(
              children: [
                SizedBox(height: defaultVerticalPadding * 1.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: defaultHorizontalPadding / 2),
                    Text('Popular posts', style: TextStyle(fontSize: defaultTextFontSize * 1.1, fontWeight: FontWeight.bold))
                  ]
                ),
                SizedBox(height: defaultVerticalPadding * 0.25),
              ]
            ),
            ValueListenableBuilder(
              valueListenable: isLoading,
              builder: ((context, isLoadingValue, child) {
                return ValueListenableBuilder(
                  valueListenable: posts,
                  builder: ((context, posts, child) {
                    if(!isLoadingValue){
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          if(appStateClass.postsNotifiers.value[posts[index].sender] == null){
                            return Container();
                          }
                          if(appStateClass.postsNotifiers.value[posts[index].sender]![posts[index].postID] == null){
                            return Container();
                          }
                          return ValueListenableBuilder<PostClass>(
                            valueListenable: appStateClass.postsNotifiers.value[posts[index].sender]![posts[index].postID]!.notifier,
                            builder: ((context, postData, child) {
                              if(appStateClass.usersDataNotifiers.value[posts[index].sender] != null){
                                return ValueListenableBuilder(
                                  valueListenable: appStateClass.usersDataNotifiers.value[posts[index].sender]!.notifier, 
                                  builder: ((context, userData, child) {
                                    if(!postData.deleted){
                                      if(userData.blocksCurrentID){
                                        return Container();
                                      }
                                      return ValueListenableBuilder(
                                        valueListenable: appStateClass.usersSocialsNotifiers.value[posts[index].sender]!.notifier, 
                                        builder: ((context, userSocials, child) { 
                                          if(userData.private && !userSocials.followedByCurrentID && userData.userID != appStateClass.currentID){
                                            return Container();
                                          }
                                          return CustomPostWidget(
                                            postData: postData, 
                                            senderData: userData,
                                            senderSocials: userSocials,
                                            pageDisplayType: PostDisplayType.explore,
                                            skeletonMode: false,
                                            key: UniqueKey()
                                          );
                                        })
                                      );
                                    }
                                    return Container();
                                  })
                                );
                              }
                              return Container();
                            }),
                          );
                        }
                      );
                    }else{
                      return Skeletonizer(
                        enabled: true,
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: exploreDataLimit,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return CustomPostWidget(
                              postData: PostClass.getFakeData(), 
                              senderData: UserDataClass.getFakeData(), 
                              senderSocials: UserSocialClass.getFakeData(), 
                              pageDisplayType: PostDisplayType.explore, 
                              skeletonMode: true
                            );
                          }
                        )
                      );
                    }
                  })
                );
              })
            ),
            Column(
              children: [
                SizedBox(height: defaultVerticalPadding * 1.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: defaultHorizontalPadding / 2),
                    Text('Popular users', style: TextStyle(fontSize: defaultTextFontSize * 1.1, fontWeight: FontWeight.bold))
                  ]
                ),
                SizedBox(height: defaultVerticalPadding * 0.25),
              ]
            ),
            ValueListenableBuilder(
              valueListenable: isLoading,
              builder: ((context, isLoadingValue, child) {
                return ValueListenableBuilder(
                  valueListenable: users,
                  builder: ((context, users, child) {
                    if(!isLoadingValue){
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          if(appStateClass.usersDataNotifiers.value[users[index]] != null){
                            return ValueListenableBuilder(
                              valueListenable: appStateClass.usersDataNotifiers.value[users[index]]!.notifier, 
                              builder: ((context, userData, child) {
                                return ValueListenableBuilder(
                                  valueListenable: appStateClass.usersSocialsNotifiers.value[users[index]]!.notifier, 
                                  builder: ((context, userSocial, child) {
                                    return CustomUserDataWidget(
                                      userData: userData,
                                      userSocials: userSocial,
                                      userDisplayType: UserDisplayType.explore,
                                      isLiked: null,
                                      isBookmarked: null,
                                      profilePageUserID: null,
                                      skeletonMode: false,
                                      key: UniqueKey()
                                    );
                                  })
                                );
                              })
                            );
                          }
                          return Container();
                        }
                      );
                    }else{
                      return Skeletonizer(
                        enabled: true,
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: exploreDataLimit,
                          itemBuilder: (context, index) {
                            return CustomUserDataWidget(
                              userData: UserDataClass.getFakeData(), 
                              userSocials: UserSocialClass.getFakeData(), 
                              userDisplayType: UserDisplayType.explore, 
                              profilePageUserID: null, 
                              isLiked: false, 
                              isBookmarked: false, 
                              skeletonMode: true
                            );
                          }
                        )
                      );
                    }
                  })
                );
              })
            )
          ],
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: displayFloatingBtn,
        builder: (BuildContext context, bool visible, Widget? child) {
          return Visibility(
            visible: visible,
            child: FloatingActionButton( 
              heroTag: UniqueKey(),
              onPressed: () {  
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 10),
                  curve:Curves.fastOutSlowIn
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          );
        }
      )
    );
  }

  @override
  bool get wantKeepAlive => true;
}
