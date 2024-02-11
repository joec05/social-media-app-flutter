import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ChatsWidget extends StatelessWidget {
  const ChatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ChatsWidgetStateful();
  }
}

class _ChatsWidgetStateful extends StatefulWidget {
  const _ChatsWidgetStateful();

  @override
  State<_ChatsWidgetStateful> createState() => _ChatsWidgetStatefulState();
}

class _ChatsWidgetStatefulState extends State<_ChatsWidgetStateful> with AutomaticKeepAliveClientMixin, LifecycleListenerMixin{
  late ChatsController controller;

  @override
  void initState(){
    super.initState();
    controller = ChatsController(context);
    controller.initializeController();
  }

  @override
  void dispose(){
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Chats'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: controller.displayFloatingBtn,
            builder: (BuildContext context, bool visible, Widget? child) {
              return Column(
                children: [
                  Visibility(
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
                  ),
                  SizedBox(height: getScreenHeight() * 0.02),
                ],
              );
            }
          ),
          FloatingActionButton( 
            heroTag: 'search users',
            onPressed: () {
              runDelay(() => Navigator.push(
                context,
                SliderRightToLeftRoute(
                  page: const SearchChatUsersWidget()
                )
              ), navigatorDelayTime);
            },
            backgroundColor: Colors.lightBlue,
            child: const Icon(Icons.mail),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: controller.loadingState,
        builder: ((context, loadingStateValue, child) {
          if(shouldCallSkeleton(loadingStateValue)){
            return shimmerSkeletonWidget(
              ListView.builder(
                itemCount: postsPaginationLimit,
                itemBuilder: (builder, context){
                  return CustomChatWidget(
                    chatData: ChatDataClass.getFakeData(),
                    recipientData: UserDataClass.getFakeData(), 
                    recipientSocials: UserSocialClass.getFakeData(), 
                    skeletonMode: true,
                    deleteChat: (){}
                  );
                },
              )
            );
          }
          return ListenableBuilder(
            listenable: Listenable.merge([
              controller.paginationStatus,
              controller.canPaginate,
              controller.chats
            ]),
            builder: (context, child){
              PaginationStatus loadingStatusValue = controller.paginationStatus.value;
              bool canPaginateValue = controller.canPaginate.value;
              List<ChatDataNotifier> chatsList = controller.chats.value;
              return LoadMoreBottom(
                addBottomSpace: canPaginateValue,
                loadMore: () async{
                  if(canPaginateValue){
                    await controller.loadMoreChats();
                  }
                },
                status: loadingStatusValue,
                refresh: controller.refresh,
                child: CustomScrollView(
                  controller: controller.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverList(delegate: SliverChildBuilderDelegate(
                      childCount: chatsList.length, 
                      (context, index) {
                        return ValueListenableBuilder(
                          valueListenable: chatsList[index].notifier, 
                          builder: ((context, chatData, child) {
                            if(chatData.type == 'private'){
                              return ListenableBuilder(
                                listenable: Listenable.merge([
                                  appStateClass.usersDataNotifiers.value[chatData.recipient]!.notifier,
                                  appStateClass.usersSocialsNotifiers.value[chatData.recipient]!.notifier
                                ]),
                                builder: (context, child){
                                  UserDataClass userData = appStateClass.usersDataNotifiers.value[chatData.recipient]!.notifier.value;
                                  UserSocialClass userSocials = appStateClass.usersSocialsNotifiers.value[chatData.recipient]!.notifier.value;
                                  return CustomChatWidget(
                                    chatData: chatData, 
                                    recipientData: userData, 
                                    recipientSocials: userSocials, 
                                    key: UniqueKey(),
                                    deleteChat: controller.deletePrivateChat, 
                                    skeletonMode: false,
                                  );
                                }
                              );
                            }else{
                              if(chatData.groupProfileData!.recipients.contains(appStateClass.currentID)){
                                if(chatData.latestMessageData.messageID.isEmpty){
                                  return CustomChatWidget(
                                    chatData: chatData, 
                                    recipientData: null, 
                                    recipientSocials: null, 
                                    key: UniqueKey(),
                                    deleteChat: controller.deleteGroupChat, 
                                    skeletonMode: false
                                  );
                                }
                                return ListenableBuilder(
                                  listenable: Listenable.merge([
                                    appStateClass.usersDataNotifiers.value[chatData.latestMessageData.sender]!.notifier,
                                    appStateClass.usersSocialsNotifiers.value[chatData.latestMessageData.sender]!.notifier
                                  ]),
                                  builder: (context, child){
                                    return CustomChatWidget(
                                      chatData: chatData, 
                                      recipientData: null, 
                                      recipientSocials: null, 
                                      key: UniqueKey(),
                                      deleteChat: controller.deleteGroupChat, 
                                      skeletonMode: false
                                    );
                                  }
                                );
                              }
                            }
                            return Container();
                          })
                        );
                        
                      }
                    ))
                  ]
                )
              );
            }
          );
        })
      ),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}