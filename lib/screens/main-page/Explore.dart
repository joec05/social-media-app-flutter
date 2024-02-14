import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

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
  late ExploreController controller;

  @override
  void initState(){
    super.initState();
    controller = ExploreController(context);
    controller.initializeController();
 }

  @override void dispose(){
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async{
          controller.loadingState.value = LoadingState.refreshing;
          await controller.fetchExploreData();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: controller.scrollController,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: controller.verifySearchedFormat,
              builder: (context, bool searchedVerified, child){
                return SizedBox(
                  width: getScreenWidth(),
                  height: getScreenHeight() * 0.075,
                  child: TextField(
                    controller: controller.searchedController,
                    decoration: generateSearchTextFieldDecoration(
                      'your interests', Icons.search,
                      searchedVerified ? (){
                        runDelay(() => Navigator.push(
                          context,
                          SliderRightToLeftRoute(
                            page: SearchedWidget(searchedText: controller.searchedController.text)
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
            ListenableBuilder(
              listenable: Listenable.merge([
                controller.loadingState,
                controller.hashtags
              ]),
              builder: (context, child){
                LoadingState loadingStateValue = controller.loadingState.value;
                List<HashtagClass> hashtagsValue = controller.hashtags.value;
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
                      itemCount: controller.exploreDataLimit,
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
              },
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
            ListenableBuilder(
              listenable: Listenable.merge([
                controller.loadingState,
                controller.posts
              ]),
              builder: (context, child){
                LoadingState loadingStateValue = controller.loadingState.value;
                List<DisplayPostDataClass> postsList = controller.posts.value;
                if(!shouldCallSkeleton(loadingStateValue)){
                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: postsList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      if(appStateRepo.postsNotifiers.value[postsList[index].sender] == null){
                        return Container();
                      }
                      if(appStateRepo.postsNotifiers.value[postsList[index].sender]![postsList[index].postID] == null){
                        return Container();
                      }
                      return ValueListenableBuilder<PostClass>(
                        valueListenable: appStateRepo.postsNotifiers.value[postsList[index].sender]![postsList[index].postID]!.notifier,
                        builder: ((context, postData, child) {
                          if(appStateRepo.usersDataNotifiers.value[postsList[index].sender] != null){
                            return ValueListenableBuilder(
                              valueListenable: appStateRepo.usersDataNotifiers.value[postsList[index].sender]!.notifier, 
                              builder: ((context, UserDataClass userData, child) {
                                if(!postData.deleted){
                                  if(userData.blocksCurrentID){
                                    return Container();
                                  }
                                  return ValueListenableBuilder(
                                    valueListenable: appStateRepo.usersSocialsNotifiers.value[postsList[index].sender]!.notifier, 
                                    builder: ((context, UserSocialClass userSocials, child) { 
                                      if(userData.private && !userSocials.followedByCurrentID && userData.userID != appStateRepo.currentID){
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
                      itemCount: controller.exploreDataLimit,
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
              }
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
            ListenableBuilder(
              listenable: Listenable.merge([
                controller.loadingState,
                controller.users
              ]),
              builder: (context, child){
                LoadingState loadingStateValue = controller.loadingState.value;
                List<String> usersList = controller.users.value;
                if(!shouldCallSkeleton(loadingStateValue)){
                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: usersList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      if(appStateRepo.usersDataNotifiers.value[usersList[index]] != null){
                        return ListenableBuilder(
                          listenable: Listenable.merge([
                            appStateRepo.usersDataNotifiers.value[usersList[index]]!.notifier,
                            appStateRepo.usersSocialsNotifiers.value[usersList[index]]!.notifier
                          ]),
                          builder: (context, child){
                            UserDataClass userData = appStateRepo.usersDataNotifiers.value[usersList[index]]!.notifier.value;
                            UserSocialClass userSocial = appStateRepo.usersSocialsNotifiers.value[usersList[index]]!.notifier.value;
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
                          }
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
                      itemCount: controller.exploreDataLimit,
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
              }
            )
          ],
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: controller.displayFloatingBtn,
        builder: (BuildContext context, bool visible, Widget? child) {
          return Visibility(
            visible: visible,
            child: FloatingActionButton( 
              heroTag: UniqueKey(),
              onPressed: () {  
                controller.scrollController.animateTo(
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
