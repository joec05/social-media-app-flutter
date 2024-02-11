import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

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
  late GroupProfileController controller;

  @override
  void initState(){
    super.initState();
    controller = GroupProfileController(
      context, 
      widget.chatID, 
      ValueNotifier(widget.groupProfileData)
    );
    controller.initializeController();
  }

  @override void dispose(){
    super.dispose();
    controller.dispose();
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
                valueListenable: controller.groupProfile, 
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
                          page: GroupMembersPage(usersID: controller.groupProfile.value.recipients)
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
                          page: EditGroupProfileStateful(
                            chatID: controller.chatID, 
                            groupProfileData: controller.groupProfile.value
                          )
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
                          page: AddUsersToGroupWidget(
                            chatID: controller.chatID, 
                            groupProfileData: controller.groupProfile.value
                          )
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
                    onTapped: () => controller.leaveGroup(),
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