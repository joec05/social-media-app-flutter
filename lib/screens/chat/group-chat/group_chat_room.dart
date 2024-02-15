import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';

class GroupChatRoomWidget extends StatelessWidget {
  final String? chatID;
  final List<String>? recipients;
  const GroupChatRoomWidget({super.key, required this.chatID, required this.recipients});

  @override
  Widget build(BuildContext context) {
    return _GroupChatRoomWidgetStateful(chatID: chatID, recipients: recipients);
  }
}

class _GroupChatRoomWidgetStateful extends StatefulWidget {
  final String? chatID;
  final List<String>? recipients;
  const _GroupChatRoomWidgetStateful({required this.chatID, required this.recipients});

  @override
  State<_GroupChatRoomWidgetStateful> createState() => _GroupChatRoomWidgetStatefulState();
}

class _GroupChatRoomWidgetStatefulState extends State<_GroupChatRoomWidgetStateful> with LifecycleListenerMixin{
  late GroupChatController chatController;
  late UploadController uploadController;

  @override
  void initState(){
    super.initState();
    chatController = GroupChatController(
      context, widget.chatID, widget.recipients
    );
    uploadController = UploadController(context);
    chatController.initializeController();
    uploadController.initializeController();
  }
  
  @override
  void dispose(){
    super.dispose();
    chatController.dispose();
    uploadController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        titleSpacing: defaultAppBarTitleSpacing,
        title: ValueListenableBuilder(
          valueListenable: chatController.groupProfile, 
          builder: ((context, groupProfileData, child) {
            if(groupProfileData.profilePicLink.isNotEmpty){
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: (){
                      if(chatController.chatID.value != null){
                        runDelay(() => Navigator.push(
                          context,
                          SliderRightToLeftRoute(
                            page: GroupProfilePageWidget(
                              chatID: chatController.chatID.value!, 
                              groupProfileData: chatController.groupProfile.value
                            )
                          )
                        ), navigatorDelayTime);
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start, 
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: getScreenWidth() * 0.075,
                                    height: getScreenWidth() * 0.075,
                                    decoration: BoxDecoration(
                                      border: Border.all(width: 2),
                                      borderRadius: BorderRadius.circular(100),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          groupProfileData.profilePicLink
                                        ), fit: BoxFit.fill
                                      )
                                    ),
                                  )
                                ]
                              ),
                              SizedBox(width: getScreenWidth() * 0.02),
                              Expanded( 
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(StringEllipsis.convertToEllipsis(groupProfileData.name), maxLines: 1, overflow: TextOverflow.ellipsis)
                                  ],
                                )
                              )
                            ],
                          )
                        ),
                      ],
                    )
                  ),
                ],
              );
            }
            return SizedBox(
              width: getScreenWidth() * 0.075,
              height: getScreenWidth() * 0.075,
            );
          })
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: chatController.chatID,
            builder: (context, chatIDValue, child){
              if(chatIDValue != null){
                return PopupMenuButton(
                  onSelected: (result) {
                    if(result == 'Delete Chat'){
                      Navigator.pop(context, GroupMessageActions.deleteChat);
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry>[
                    const PopupMenuItem(
                      value: 'Delete Chat',
                      child: Text('Delete Chat')
                    ),
                  ]
                );
              }
              return Container();
            }
          )
        ]
      ),
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([
              chatController.paginationStatus,
              chatController.canPaginate,
              chatController.messages
            ]),
            builder: (context, child){
              PaginationStatus loadingStatusValue = chatController.paginationStatus.value;
              bool canPaginateValue = chatController.canPaginate.value;
              List<GroupMessageNotifier> messagesList = chatController.messages.value;
              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        LoadMoreBottom(
                          addBottomSpace: canPaginateValue,
                          loadMore: () async{
                            if(canPaginateValue){
                              await chatController.loadMoreChats();
                            }
                          },
                          status: loadingStatusValue,
                          refresh: null,
                          child: CustomScrollView(
                            controller: chatController.scrollController,
                            shrinkWrap: true,
                            reverse: true,
                            slivers: 
                            <Widget>[
                              SliverList(delegate: SliverChildBuilderDelegate(
                                childCount: messagesList.length,
                                (context, index) {
                                  return ListenableBuilder(
                                    listenable: Listenable.merge([
                                      messagesList[index].notifier,
                                      appStateRepo.usersDataNotifiers.value[
                                        messagesList[index].notifier.value.sender
                                      ]!.notifier
                                    ]),
                                    builder: (context, child){
                                      GroupMessageClass messageData = messagesList[index].notifier.value;
                                      UserDataClass userData = appStateRepo.usersDataNotifiers.value[messageData.sender]!.notifier.value;
                                      return CustomGroupMessage(
                                        key: UniqueKey(),
                                        chatID: chatController.chatID.value,
                                        groupMessageData: messageData,
                                        senderData: userData,
                                        recipients: chatController.groupProfile.value.recipients,
                                        previousMessageUploadTime: index + 1 == messagesList.length ? 
                                          '' : messagesList[index + 1].notifier.value.uploadTime,
                                      );
                                    }
                                  );
                                }
                              )),
                            ]
                          )
                        )
                      ]
                    )
                  ),
                  Container(
                    width: getScreenWidth(),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(width: 1)),
                    ),
                    child: ValueListenableBuilder<List>(
                      valueListenable: uploadController.mediasComponents,
                      builder: (context, mediasComponentsList, child) {
                        if(mediasComponentsList.isEmpty){
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () => uploadController.pickImage(ImageSource.gallery),
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: getScreenWidth() * 0.015, 
                                        vertical: getScreenHeight() * 0.01
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Icon(Icons.photo, size: writePostIconSize,
                                        color: uploadController.mediasComponents.value.length == maxMessageMediaCount ?
                                          Colors.grey : Theme.of(context).iconTheme.color
                                      ),
                                    )
                                  ),
                                  GestureDetector(
                                    onTap: () => uploadController.pickImage(ImageSource.camera),
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: getScreenWidth() * 0.015,
                                        vertical: getScreenHeight() * 0.01
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Icon(Icons.camera_alt_sharp, size: writePostIconSize,
                                        color: uploadController.mediasComponents.value.length == maxMessageMediaCount ?
                                          Colors.grey : Theme.of(context).iconTheme.color
                                      ),
                                    )
                                  ),
                                  GestureDetector(
                                    onTap: () => uploadController.pickVideo(),
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: getScreenWidth() * 0.015,
                                        vertical: getScreenHeight() * 0.01
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Icon(Icons.video_file_sharp, size: writePostIconSize,
                                        color: uploadController.mediasComponents.value.length == maxMessageMediaCount ?
                                          Colors.grey : Theme.of(context).iconTheme.color
                                      ),
                                    )
                                  ),
                                ],
                              )
                            ]
                          );
                        }else{
                          return Column(
                            children: [
                              for(int i = 0; i < mediasComponentsList.length; i++)
                              uploadController.mediaComponentIndex(mediasComponentsList[i], i)
                            ],
                          );
                        }
                      }
                    ) 
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: uploadController.verifyTextFormat,
                    builder: (context, bool messageVerified, child){
                      return Stack(
                        children: [
                          TextField(
                            controller: uploadController.textController,
                            decoration: generateMessageTextFieldDecoration('message'),
                            minLines: messageDraftTextFieldMinLines,
                            maxLines: messageDraftTextFieldMaxLines,
                            maxLength: maxPostWordLimit,
                            onChanged: (value){
                              uploadController.listenTextField(value);
                              uploadController.listenTextController(value);
                            },
                            onEditingComplete: (){
                              uploadController.listenTextController(
                                uploadController.textController.text
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: ListenableBuilder(
                              listenable: Listenable.merge([
                                uploadController.mediasComponents,
                                chatController.isLoading
                              ]),
                              builder: (context, child){
                                List<Widget> mediasComponentsList = uploadController.mediasComponents.value;
                                bool isLoadingValue = chatController.isLoading.value;
                                return Container(
                                  width: getScreenWidth() * 0.125,
                                  color: Colors.transparent, 
                                  child: TextButton(
                                    onPressed: (messageVerified || mediasComponentsList.isNotEmpty) && !isLoadingValue ?
                                      () => uploadController.sendGroupMessage(
                                        chatController
                                      ) : null,
                                    child: const Icon(Icons.send, size: 25)
                                  ),
                                );
                              }
                            )
                          )
                        ],
                      );
                    }
                  ),
                ]
              );
            }
          ),
          ListenableBuilder(
            listenable: Listenable.merge([
              chatController.isLoading,
              uploadController.isUploading
            ]),
            builder: (context, child){
              bool isLoadingValue = chatController.isLoading.value;
              bool isUploadingValue = uploadController.isUploading.value;
              if(isLoadingValue || isUploadingValue){
                return loadingPageWidget();
              }
              return Container();
            }
          )
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: chatController.displayFloatingBtn,
        builder: (BuildContext context, bool visible, Widget? child) {
          return Visibility(
            visible: visible,
            child: FloatingActionButton( 
              heroTag: UniqueKey(),
              onPressed: () {  
                chatController.scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 10),
                  curve:Curves.fastOutSlowIn
                );
              },
              child: const Icon(Icons.arrow_downward),
            )
          );
        }
      )
    );
  }
  
  bool get wantKeepAlive => true;
}