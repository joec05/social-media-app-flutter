// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/GroupChatRoom.dart';
import 'package:social_media_app/PrivateChatRoom.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/class/ChatDataClass.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import '../GroupProfilePage.dart';
import '../class/UserDataClass.dart';
import '../class/UserSocialClass.dart';
import '../extenstions/StringEllipsis.dart';

class CustomChatWidget extends StatefulWidget {
  final ChatDataClass chatData;
  final UserDataClass? recipientData;
  final UserSocialClass? recipientSocials;
  final Function deleteChat;

  const CustomChatWidget({
    super.key, required this.chatData, required this.recipientData, required this.recipientSocials,
    required this.deleteChat
  });

  @override
  _CustomChatWidgetState createState() => _CustomChatWidgetState();
}

class _CustomChatWidgetState extends State<CustomChatWidget> {
  late ChatDataClass chatData;
  late UserDataClass? recipientData;
  late UserSocialClass? recipientSocials;

  @override
  void initState(){
    super.initState();
    chatData = widget.chatData;
    recipientData = widget.recipientData;
    recipientSocials = widget.recipientSocials;
  }

  @override void dispose(){
    super.dispose();
  }

  void navigateToGroupChat() async{
    try {
      runDelay(()async {
        var action = await Navigator.push(
          context,
          SliderRightToLeftRoute(
            page: GroupChatRoomWidget(chatID: chatData.chatID, recipients: null)
          )
        );
        if(action != null && action == GroupMessageActions.deleteChat){
          widget.deleteChat(chatData.chatID);
        }
      },  navigatorDelayTime);
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  void navigateToPrivateChat() async{
    try {
      runDelay(()async {
        var action = await Navigator.push(
          context,
          SliderRightToLeftRoute(
            page: PrivateChatRoomWidget(chatID: chatData.chatID, recipient: chatData.recipient)
          )
        );
        if(action != null && action == PrivateMessageActions.deleteChat){
          widget.deleteChat(chatData.chatID);
        }
      }, navigatorDelayTime);
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    String latestMessageSender = chatData.latestMessageData.sender;
    bool senderIsCurrentID = false;
    String subject = '';
    if(chatData.latestMessageData.type == 'message'){
      senderIsCurrentID = latestMessageSender == fetchReduxDatabase().currentID;
      subject = senderIsCurrentID ? 'You' : fetchReduxDatabase().usersDatasNotifiers.value[latestMessageSender]!.notifier.value.name;
    }
    if(chatData.deleted){
      return Container();
    }
    if(chatData.type == 'private'){
      if(recipientData!.blockedByCurrentID || recipientData!.blocksCurrentID || recipientData!.suspended || recipientData!.deleted){
        return Container();
      }
      
      return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
        color: Colors.transparent,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              navigateToPrivateChat();
            },
            splashFactory: InkRipple.splashFactory,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: (){
                                navigateToProfilePage(context, recipientData!.userID);
                              },
                              child: Container(
                                width: getScreenWidth() * 0.125, height: getScreenWidth() * 0.125,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 2, color: Colors.white),
                                  borderRadius: BorderRadius.circular(100),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      recipientData!.profilePicLink
                                    ), fit: BoxFit.fill
                                  )
                                ),
                              ),
                            ),
                            SizedBox(
                              width: getScreenWidth() * 0.03
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Flexible(child: Text(StringEllipsis.convertToEllipsis(recipientData!.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.bold))),
                                      recipientData!.verified && !recipientData!.suspended && !recipientData!.deleted ?
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: iconsBesideNameProfileMargin
                                            ),
                                            Icon(Icons.verified_rounded, size: verifiedIconProfileWidgetSize),
                                          ]
                                        )
                                      : Container(),
                                      recipientData!.private && !recipientData!.suspended && !recipientData!.deleted ?
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: iconsBesideNameProfileMargin
                                            ),
                                            Icon(FontAwesomeIcons.lock, size: lockIconProfileWidgetSize),
                                          ],
                                        )
                                      : Container(),
                                      recipientData!.mutedByCurrentID && !recipientData!.suspended && !recipientData!.deleted ?
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: iconsBesideNameProfileMargin
                                            ),
                                            Icon(FontAwesomeIcons.volumeXmark, size: muteIconProfileWidgetSize),
                                          ],
                                        )
                                      : Container()
                                    ],
                                  ),
                                  SizedBox(
                                    height: getScreenHeight() * 0.003
                                  ),
                                  Text(chatData.latestMessageData.content.isEmpty ? '' : '$subject: ${chatData.latestMessageData.content}', maxLines: 3, style: TextStyle(fontSize: defaultTextFontSize)),
                                  SizedBox(
                                    height: getScreenHeight() * 0.003
                                  ),
                                  Text(chatData.latestMessageData.uploadTime.isNotEmpty ? getTimeDifference(chatData.latestMessageData.uploadTime) : '', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]
              )
            )
          )
        )
      );
    }else{
      UserDataClass? senderProfileData = chatData.latestMessageData.messageID.isNotEmpty ? fetchReduxDatabase().usersDatasNotifiers.value[chatData.latestMessageData.sender]!.notifier.value : null;
      return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
        color: Colors.transparent,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (){
              navigateToGroupChat();
            },
            splashFactory: InkRipple.splashFactory,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                runDelay(() => Navigator.push(
                                  context,
                                  SliderRightToLeftRoute(
                                    page: GroupProfilePageWidget(chatID: chatData.chatID, groupProfileData: chatData.groupProfileData!)
                                  ),
                                ), navigatorDelayTime);
                              },
                              child: Container(
                                width: getScreenWidth() * 0.125, height: getScreenWidth() * 0.125,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 2, color: Colors.white),
                                  borderRadius: BorderRadius.circular(100),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      chatData.groupProfileData!.profilePicLink
                                    ), fit: BoxFit.fill
                                  )
                                ),
                              ),
                            ),
                            SizedBox(
                              width: getScreenWidth() * 0.03
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          StringEllipsis.convertToEllipsis(chatData.groupProfileData!.name),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.bold),
                                          softWrap: true,
                                        )
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: getScreenHeight() * 0.003
                                  ),
                                  Text(
                                    senderProfileData == null ? '' : 
                                    senderProfileData.blockedByCurrentID || senderProfileData.blocksCurrentID ?
                                      'This message is unavailable'
                                    :
                                      chatData.latestMessageData.type == 'message' ? '$subject: ${chatData.latestMessageData.content}' : chatData.latestMessageData.content,
                                    maxLines: 3, style: TextStyle(fontSize: defaultTextFontSize)
                                  ),
                                  SizedBox(
                                    height: getScreenHeight() * 0.003
                                  ),
                                  Text(chatData.latestMessageData.uploadTime.isNotEmpty ? getTimeDifference(chatData.latestMessageData.uploadTime) : '', style: const TextStyle(fontSize: 12)),
                                ],
                              
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ),
                ]
              )
            )
          )
        )
      );
    }
  }

}