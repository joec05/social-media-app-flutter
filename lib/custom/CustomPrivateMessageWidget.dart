// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import '../class/MediaDataClass.dart';
import '../class/PrivateMessageClass.dart';
import '../socket/main.dart';
import 'CustomButton.dart';
import 'CustomTextSpan.dart';

class CustomPrivateMessage extends StatefulWidget {
  final String? chatID;
  final String chatRecipient;
  final PrivateMessageClass privateMessageData;

  const CustomPrivateMessage({
    super.key,
    required this.chatID,
    required this.chatRecipient,
    required this.privateMessageData
  });

  @override
  _CustomPrivateMessageState createState() => _CustomPrivateMessageState();
  
}

var dio = Dio();

class _CustomPrivateMessageState extends State<CustomPrivateMessage> {
  late PrivateMessageClass privateMessageData;

  @override
  void initState(){
    super.initState();
    privateMessageData = widget.privateMessageData;
  }

  @override void dispose(){
    super.dispose();
  }

  void deletePrivateMessage() async{
    try {
      socket.emit("delete-private-message-to-server", {
        'chatID': widget.chatID,
        'messageID': privateMessageData.messageID,
        'currentID': fetchReduxDatabase().currentID,
        'recipient': widget.chatRecipient
      });
      String stringified = jsonEncode({
        'chatID': widget.chatID,
        'messageID': privateMessageData.messageID,
        'currentID': fetchReduxDatabase().currentID,
      });
      var res = await dio.patch('$serverDomainAddress/users/deletePrivateMessage', data: stringified);
      if(res.data.isNotEmpty){
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  void deletePrivateMessageForAll() async{
    try {
      socket.emit("delete-private-message-for-all-to-server", {
        'chatID': widget.chatID,
        'messageID': privateMessageData.messageID,
        'currentID': fetchReduxDatabase().currentID,
        'recipient': widget.chatRecipient,
        'content': ''
      });
      String stringified = jsonEncode({
        'chatID': widget.chatID,
        'messageID': privateMessageData.messageID,
        'currentID': fetchReduxDatabase().currentID,
        'recipient': widget.chatRecipient
      });
      var res = await dio.patch('$serverDomainAddress/users/deletePrivateMessageForAll', data: stringified);
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
                        runDelay(() => deletePrivateMessage(), actionDelayTime);
                      },
                      buttonText: 'Delete message',
                      width: double.infinity,
                      height: getScreenHeight() * 0.075,
                      buttonColor: Colors.transparent,
                      setBorderRadius: false,
                    )
                  )
                ),
                privateMessageData.sender == fetchReduxDatabase().currentID ?
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (){},
                      splashFactory: InkRipple.splashFactory,
                      child: CustomButton(
                        onTapped: (){
                          Navigator.pop(bottomSheetContext);
                          runDelay(() => deletePrivateMessageForAll(), actionDelayTime);
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
    if(privateMessageData.deletedList.contains(fetchReduxDatabase().currentID)){
      return Container();
    }

    List<MediaDatasClass> mediasDatas = privateMessageData.mediasDatas;
    return InkWell(
      onLongPress: () {
        displayMessageBottomSheet();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: privateMessageData.sender == fetchReduxDatabase().currentID ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for(int i = 0; i < mediasDatas.length; i++)
                mediaDataMessageComponentWidget(mediasDatas[i], context)
              ],
            ),
            Align(
              alignment: privateMessageData.sender == fetchReduxDatabase().currentID ? Alignment.topRight : Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(width: 2, color: Colors.white),
                  color: privateMessageData.sender == fetchReduxDatabase().currentID ? Colors.blue : Colors.grey.withOpacity(0.5)
                ),
                child: Column(
                  children: [
                    DisplayTextComponent(
                      text: privateMessageData.content, tagsPressable: true, overflow: TextOverflow.ellipsis, 
                      maxLines: 3, style: TextStyle(fontSize: defaultTextFontSize), alignment: TextAlign.left, 
                      context: context
                    )
                  ],
                )
              )
            ),
            Column(                
              children: [
                SizedBox(height: getScreenHeight() * 0.005),
                Text('${getCleanTimeFormat(privateMessageData.uploadTime)} - ${getTimeDifference(privateMessageData.uploadTime)}', style: const TextStyle(fontSize: 12)),
              ],
            )
          ],
        )
      ),
    );
  }

}