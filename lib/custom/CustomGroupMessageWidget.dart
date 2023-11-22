// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import '../ProfilePage.dart';
import '../class/MediaDataClass.dart';
import '../class/GroupMessageClass.dart';
import '../class/UserDataClass.dart';
import '../socket/main.dart';
import 'CustomButton.dart';
import 'CustomTextSpan.dart';

class CustomGroupMessage extends StatefulWidget {
  final String? chatID;
  final GroupMessageClass groupMessageData;
  final UserDataClass senderData;
  final List<String> recipients;

  const CustomGroupMessage({
    super.key,
    required this.chatID,
    required this.groupMessageData,
    required this.senderData,
    required this.recipients
  });

  @override
  _CustomGroupMessageState createState() => _CustomGroupMessageState();
  
}

var dio = Dio();

class _CustomGroupMessageState extends State<CustomGroupMessage> {
  late GroupMessageClass groupMessageData;
  late UserDataClass senderData;

  @override
  void initState(){
    super.initState();
    groupMessageData = widget.groupMessageData;
    senderData = widget.senderData;
  }

  @override void dispose(){
    super.dispose();
  }

  void deleteGroupMessage() async{
    try {
      socket.emit("delete-group-message-to-server", {
        'chatID': widget.chatID,
        'messageID': groupMessageData.messageID,
        'currentID': fetchReduxDatabase().currentID,
      });
      String stringified = jsonEncode({
        'chatID': widget.chatID,
        'messageID': groupMessageData.messageID,
        'currentID': fetchReduxDatabase().currentID,
      });
      var res = await dio.patch('$serverDomainAddress/users/deleteGroupMessage', data: stringified);
      if(res.data.isNotEmpty){
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  void deleteGroupMessageForAll() async{
    try {
      socket.emit("delete-group-message-for-all-to-server", {
        'chatID': widget.chatID,
        'messageID': groupMessageData.messageID,
        'currentID': fetchReduxDatabase().currentID,
        'content': '',
        'recipients': widget.recipients
      });
      String stringified = jsonEncode({
        'chatID': widget.chatID,
        'messageID': groupMessageData.messageID,
        'currentID': fetchReduxDatabase().currentID,
        'recipients': widget.recipients
      });
      var res = await dio.patch('$serverDomainAddress/users/deleteGroupMessageForAll', data: stringified);
      if(res.data.isNotEmpty){
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  void displayMessageBottomSheet(){
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [     
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (){},
                    splashFactory: InkRipple.splashFactory,
                    child: CustomButton(
                      onTapped: (){
                        Navigator.pop(bottomSheetContext);
                        runDelay(() => deleteGroupMessage(), actionDelayTime);
                      },
                      buttonText: 'Delete message',
                      width: double.infinity,
                      height: getScreenHeight() * 0.075,
                      buttonColor: Colors.transparent,
                      setBorderRadius: false,
                    )
                  )
                ),
                groupMessageData.sender == fetchReduxDatabase().currentID ?
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (){},
                      splashFactory: InkRipple.splashFactory,
                      child: CustomButton(
                        onTapped: (){
                          Navigator.pop(bottomSheetContext);
                          runDelay(() => deleteGroupMessageForAll(), actionDelayTime);
                        },
                        buttonText: 'Delete message for everyone',
                        width: double.infinity,
                        height: getScreenHeight() * 0.075,
                        buttonColor: Colors.transparent,
                        setBorderRadius: false,
                      )
                    )
                  )
                : Container()
              ]
            )
          )
        );
      }
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if(groupMessageData.deletedList.contains(fetchReduxDatabase().currentID)){
      return Container(
      );
    }
    UserDataClass senderProfileData = fetchReduxDatabase().usersDatasNotifiers.value[groupMessageData.sender]!.notifier.value;
    if(senderProfileData.blockedByCurrentID || senderProfileData.blocksCurrentID){
      return Container(
      );
    }

    if(groupMessageData.type == 'message'){
      List<MediaDatasClass> mediasDatas = groupMessageData.mediasDatas;
      return InkWell(
        onLongPress: () {
          displayMessageBottomSheet();
        },
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.015),
          child: Column(
            crossAxisAlignment: groupMessageData.sender == fetchReduxDatabase().currentID ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: groupMessageData.sender == fetchReduxDatabase().currentID ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  groupMessageData.sender != fetchReduxDatabase().currentID ?
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: (){
                            runDelay(() => Navigator.push(
                              context,
                              SliderRightToLeftRoute(
                                page: ProfilePageWidget(userID: groupMessageData.sender)
                              )
                            ), navigatorDelayTime);
                          },
                          child: Container(
                            width: getScreenWidth() * 0.075,
                            height: getScreenWidth() * 0.075,
                            decoration: BoxDecoration(
                              border: Border.all(width: 2, color: Colors.white),
                              borderRadius: BorderRadius.circular(100),
                              image: DecorationImage(
                                image: NetworkImage(
                                  senderData.profilePicLink
                                ), fit: BoxFit.fill
                              )
                            ),
                          ),
                        ),
                        SizedBox(width: getScreenWidth() * 0.01)
                      ],
                    )
                  : Container(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: groupMessageData.sender == fetchReduxDatabase().currentID ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for(int i = 0; i < mediasDatas.length; i++)
                          mediaDataMessageComponentWidget(mediasDatas[i], context)
                        ],
                      ),
                      Align(
                        alignment: groupMessageData.sender == fetchReduxDatabase().currentID ? Alignment.topRight : Alignment.topLeft,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(width: 2, color: Colors.white),
                            color: groupMessageData.sender == fetchReduxDatabase().currentID ? Colors.blue : Colors.grey.withOpacity(0.5)
                          ),
                          child: Column(
                            children: [
                              DisplayTextComponent(
                                text: groupMessageData.content, tagsPressable: true, overflow: TextOverflow.ellipsis, 
                                maxLines: 3, style: TextStyle(fontSize: defaultTextFontSize), alignment: TextAlign.left, 
                                context: context
                              )
                            ],
                          )
                        )
                      ),
                      
                    ],
                  ),
                ],
              ),
              SizedBox(height: getScreenHeight() * 0.005),
              Row(      
                mainAxisAlignment: groupMessageData.sender == fetchReduxDatabase().currentID ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: groupMessageData.sender == fetchReduxDatabase().currentID ? 0 : getScreenWidth() * 0.075,
                  ),
                  Text('${getCleanTimeFormat(groupMessageData.uploadTime)} - ${getTimeDifference(groupMessageData.uploadTime)}', style: TextStyle(fontSize: 12)),
                ],
              )
            ],
          )
        ),
      );
    }else{
      return Align(
        alignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.015),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(groupMessageData.content, style: TextStyle(fontSize: defaultTextFontSize), textAlign: TextAlign.center),
            ],
          )
        )
      );
    }
  }

}