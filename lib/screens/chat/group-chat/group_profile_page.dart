import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/chat/group-chat/group_profile_class.dart';
import 'package:social_media_app/constants/global_functions.dart';
import 'package:social_media_app/constants/global_variables.dart';
import 'package:social_media_app/custom/basic-widget/custom_button.dart';
import 'package:social_media_app/mixin/lifecycle_listener.dart';
import 'package:social_media_app/screens/chat/group-chat/add_users_to_group.dart';
import 'package:social_media_app/screens/chat/group-chat/edit_group_profile.dart';
import 'package:social_media_app/screens/chat/group-chat/group_members_page.dart';
import 'package:social_media_app/socket/main.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/app_styles.dart';
import 'package:social_media_app/transition/navigation.dart';
import 'package:uuid/uuid.dart';

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
      String senderName = appStateClass.usersDataNotifiers.value[appStateClass.currentID]!.notifier.value.name;
      String content = '$senderName has left the group';
      groupProfile.value.recipients.remove(appStateClass.currentID);
      socket.emit("leave-group-to-server", {
        'chatID': chatID,
        'messageID': messageID,
        'content': content,
        'type': 'leave_group',
        'sender': appStateClass.currentID,
        'recipients': groupProfile.value.recipients,
        'mediasDatas': [],
      });
      String stringified = jsonEncode({
        'chatID': chatID,
        'messageID': messageID,
        'sender': appStateClass.currentID,
        'recipients': groupProfile.value.recipients,
      });
      var res = await dio.patch('$serverDomainAddress/users/leaveGroup', data: stringified);
      if(res.data.isNotEmpty && mounted){
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
        leading: defaultLeadingWidget(context),
        title: const Text('Group Profile'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding, vertical: defaultVerticalPadding),
        child:Center(
          child: ListView(
            children: [
              ValueListenableBuilder(
                valueListenable: groupProfile, 
                builder: (context, groupProfileData, widget){
                  return Column(
                    children: [
                      Container(
                        width: getScreenWidth() * 0.2,
                        height: getScreenWidth() * 0.2,
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
                      SizedBox(
                        height: getScreenHeight() * 0.02
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(child: Text(groupProfileData.name, style: const TextStyle(fontSize: 21), textAlign: TextAlign.center)),
                        ],
                      ),
                      SizedBox(
                        height: getScreenHeight() * 0.015
                      ),
                      Text(groupProfileData.recipients.length == 1 ? '1 member' : '${groupProfileData.recipients.length} members', style: TextStyle(fontSize: defaultTextFontSize * 0.9, fontWeight: FontWeight.w600, color: Colors.blueGrey))
                    ],
                  );
                }
              ),
              SizedBox(
                height: getScreenHeight() * 0.015
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
                    height: getScreenHeight() * 0.065,
                    buttonColor: const Color.fromARGB(255, 70, 125, 170),
                    setBorderRadius: false,
                  )
                )
              ),
              SizedBox(
                height: getScreenHeight() * 0.015
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
                    height: getScreenHeight() * 0.065,
                    buttonColor: const Color.fromARGB(255, 70, 125, 170),
                    setBorderRadius: false,
                  )
                )
              ),
              SizedBox(
                height: getScreenHeight() * 0.015
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
                    height: getScreenHeight() * 0.065,
                    buttonColor: const Color.fromARGB(255, 70, 125, 170),
                    setBorderRadius: false,
                  )
                )
              ),
              SizedBox(
                height: getScreenHeight() * 0.015
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
                    height: getScreenHeight() * 0.065,
                    buttonColor: const Color.fromARGB(255, 70, 125, 170),
                    setBorderRadius: false,
                  )
                )
              )
            ],
          )
        ),
      ),
    );
  }
}