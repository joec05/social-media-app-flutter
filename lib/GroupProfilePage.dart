// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/AddUsersToGroup.dart';
import 'package:social_media_app/EditGroupProfile.dart';
import 'package:social_media_app/GroupMembersPage.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/socket/main.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import 'package:uuid/uuid.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'class/GroupProfileClass.dart';
import 'custom/CustomButton.dart';

var dio = Dio();

class GroupProfilePageWidget extends StatelessWidget {
  final String chatID;
  final GroupProfileClass groupProfileData;
  const GroupProfilePageWidget({super.key, required this.chatID, required this.groupProfileData});

  @override
  Widget build(BuildContext context) {
    return _GroupProfilePageWidgetStateful(chatID: chatID, groupProfileData: groupProfileData);
  }
}

class _GroupProfilePageWidgetStateful extends StatefulWidget {
  final String chatID;
  final GroupProfileClass groupProfileData;
  const _GroupProfilePageWidgetStateful({required this.chatID, required this.groupProfileData});

  @override
  State<_GroupProfilePageWidgetStateful> createState() => _GroupProfilePageWidgetStatefulState();
}

class _GroupProfilePageWidgetStatefulState extends State<_GroupProfilePageWidgetStateful> with LifecycleListenerMixin{
  late String chatID;
  late ValueNotifier<GroupProfileClass> groupProfile;

  @override
  void initState(){
    super.initState();
    chatID = widget.chatID;
    groupProfile = ValueNotifier(widget.groupProfileData);
    socket.on("edit-group-profile-page-$chatID", ( data ) async{
      if(mounted && data != null){
        groupProfile.value = GroupProfileClass(
          data['newData']['name'], data['newData']['profilePicLink'], data['newData']['description'], groupProfile.value.recipients
        );
      }
    });
    socket.on("send-leave-group-announcement-$chatID", ( data ) async{
      if(mounted && data != null){
        groupProfile.value = GroupProfileClass(
          groupProfile.value.name, groupProfile.value.profilePicLink, 
          groupProfile.value.description, List<String>.of(data['recipients'])
        );
      }
    });
    socket.on("send-add-users-to-group-announcement-$chatID", ( data ) async{
      if(mounted && data != null){
        groupProfile.value = GroupProfileClass(
          groupProfile.value.name, groupProfile.value.profilePicLink, 
          groupProfile.value.description, List<String>.of([...data['recipients'], ...data['addedUsersID']])
        );
      }
    });
  }

  @override void dispose(){
    super.dispose();
    groupProfile.dispose();
  }

  void leaveGroup() async{
    try {
      String messageID = const Uuid().v4();
      String senderName = fetchReduxDatabase().usersDatasNotifiers.value[fetchReduxDatabase().currentID]!.notifier.value.name;
      String content = '$senderName has left the group';
      groupProfile.value.recipients.remove(fetchReduxDatabase().currentID);
      socket.emit("leave-group-to-server", {
        'chatID': chatID,
        'messageID': messageID,
        'content': content,
        'type': 'leave_group',
        'sender': fetchReduxDatabase().currentID,
        'recipients': groupProfile.value.recipients,
        'mediasDatas': [],
      });
      String stringified = jsonEncode({
        'chatID': chatID,
        'messageID': messageID,
        'sender': fetchReduxDatabase().currentID,
        'recipients': groupProfile.value.recipients,
      });
      var res = await dio.patch('$serverDomainAddress/users/leaveGroup', data: stringified);
      if(res.data.isNotEmpty){
        Navigator.popUntil(context, (route){
          return route.settings.name == '/chats-list';
        });
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Profile'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: Center(
        child: ListView(
          children: [
            ValueListenableBuilder(
              valueListenable: groupProfile, 
              builder: (context, groupProfileData, widget){
                return Column(
                  children: [
                    Container(
                      width: getScreenWidth() * 0.25,
                      height: getScreenWidth() * 0.25,
                      decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.white),
                        borderRadius: BorderRadius.circular(100),
                        image: DecorationImage(
                          image: NetworkImage(
                            groupProfileData.profilePicLink
                          ), fit: BoxFit.fill
                        )
                      ),
                    ),
                    Text('${groupProfileData.recipients.length} members')
                  ],
                );
              }
            ),
            SizedBox(
              height: getScreenHeight() * 0.0075
            ),
            ValueListenableBuilder(
              valueListenable: groupProfile, 
              builder: (context, groupProfileData, widget){
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(child: Text(groupProfileData.name, style: const TextStyle(fontSize: 22.5), textAlign: TextAlign.center))
                  ]
                );
              }
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (){},
                splashFactory: InkRipple.splashFactory,
                child: CustomButton(
                  onTapped: (){
                    runDelay(() => Navigator.push(
                      context,
                      SliderRightToLeftRoute(
                        page: GroupMembersPage(usersID: groupProfile.value.recipients)
                      )
                    ), navigatorDelayTime);
                  },
                  buttonText: 'View members',
                  width: double.infinity,
                  height: getScreenHeight() * 0.075,
                  buttonColor: Colors.transparent,
                  setBorderRadius: false,
                )
              )
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (){},
                splashFactory: InkRipple.splashFactory,
                child: CustomButton(
                  onTapped: (){
                    runDelay(() => Navigator.push(
                      context,
                      SliderRightToLeftRoute(
                        page: EditGroupProfileStateful(chatID: chatID, groupProfileData: groupProfile.value,)
                      )
                    ), navigatorDelayTime);
                  },
                  buttonText: 'Edit group profile',
                  width: double.infinity,
                  height: getScreenHeight() * 0.075,
                  buttonColor: Colors.transparent,
                  setBorderRadius: false,
                )
              )
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (){},
                splashFactory: InkRipple.splashFactory,
                child: CustomButton(
                  onTapped: (){
                    runDelay(() => Navigator.push(
                      context,
                      SliderRightToLeftRoute(
                        page: AddUsersToGroupWidget(chatID: chatID, groupProfileData: groupProfile.value,)
                      )
                    ), navigatorDelayTime);
                  },
                  buttonText: 'Add user to group',
                  width: double.infinity,
                  height: getScreenHeight() * 0.075,
                  buttonColor: Colors.transparent,
                  setBorderRadius: false,
                )
              )
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (){},
                splashFactory: InkRipple.splashFactory,
                child: CustomButton(
                  onTapped: (){
                    leaveGroup();
                  },
                  buttonText: 'Leave group',
                  width: double.infinity,
                  height: getScreenHeight() * 0.075,
                  buttonColor: Colors.transparent,
                  setBorderRadius: false,
                )
              )
            )
          ],
        )
      ),
    );
  }
}