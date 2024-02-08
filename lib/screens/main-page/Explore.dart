import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/attachment/media_data_class.dart';
import 'package:social_media_app/class/display/display_post_data_class.dart';
import 'package:social_media_app/class/post/post_class.dart';
import 'package:social_media_app/class/tagging/hashtag_class.dart';
import 'package:social_media_app/class/user/user_data_class.dart';
import 'package:social_media_app/class/user/user_social_class.dart';
import 'package:social_media_app/constants/app_state_actions.dart';
import 'package:social_media_app/constants/global_enums.dart';
import 'package:social_media_app/constants/global_functions.dart';
import 'package:social_media_app/constants/global_variables.dart';
import 'package:social_media_app/custom/tagging/custom_hashtag_widget.dart';
import 'package:social_media_app/custom/uploaded-content/custom_post_widget.dart';
import 'package:social_media_app/custom/user/custom_user_data_widget.dart';
import 'package:social_media_app/mixin/lifecycle_listener.dart';
import 'package:social_media_app/screens/search/Searched.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/app_styles.dart';
import 'package:social_media_app/transition/navigation.dart';

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
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
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
      doSomethingWithException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async{
          loadingState.value = LoadingState.refreshing;
          await fetchExploreData();
        },
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
              valueListenable: loadingState,
              builder: ((context, loadingStateValue, child) {
                return ValueListenableBuilder(
                  valueListenable: hashtags, 
                  builder: (context, hashtagsValue, child){
                    if(!shouldCallSkeleton(loadingStateValue)){
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
                      return shimmerSkeletonWidget(
                        ListView.builder(
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
              valueListenable: loadingState,
              builder: ((context, loadingStateValue, child) {
                return ValueListenableBuilder(
                  valueListenable: posts,
                  builder: ((context, posts, child) {
                    if(!shouldCallSkeleton(loadingStateValue)){
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
                                  builder: ((context, UserDataClass userData, child) {
                                    if(!postData.deleted){
                                      if(userData.blocksCurrentID){
                                        return Container();
                                      }
                                      return ValueListenableBuilder(
                                        valueListenable: appStateClass.usersSocialsNotifiers.value[posts[index].sender]!.notifier, 
                                        builder: ((context, UserSocialClass userSocials, child) { 
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
                      return shimmerSkeletonWidget(
                        ListView.builder(
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
              valueListenable: loadingState,
              builder: ((context, loadingStateValue, child) {
                return ValueListenableBuilder(
                  valueListenable: users,
                  builder: ((context, users, child) {
                    if(!shouldCallSkeleton(loadingStateValue)){
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          if(appStateClass.usersDataNotifiers.value[users[index]] != null){
                            return ValueListenableBuilder(
                              valueListenable: appStateClass.usersDataNotifiers.value[users[index]]!.notifier, 
                              builder: ((context, UserDataClass userData, child) {
                                return ValueListenableBuilder(
                                  valueListenable: appStateClass.usersSocialsNotifiers.value[users[index]]!.notifier, 
                                  builder: ((context, UserSocialClass userSocial, child) {
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
                      return shimmerSkeletonWidget(
                        ListView.builder(
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
