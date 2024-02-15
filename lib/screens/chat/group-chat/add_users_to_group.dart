import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class AddUsersToGroupWidget extends StatelessWidget {
  final String chatID;
  final GroupProfileClass groupProfileData;
  const AddUsersToGroupWidget({super.key, required this.chatID, required this.groupProfileData});

  @override
  Widget build(BuildContext context) {
    return _AddUsersToGroupWidgetStateful(chatID: chatID, groupProfileData: groupProfileData);
  }
}

class _AddUsersToGroupWidgetStateful extends StatefulWidget {
  final String chatID;
  final GroupProfileClass groupProfileData;
  const _AddUsersToGroupWidgetStateful({required this.chatID, required this.groupProfileData});

  @override
  State<_AddUsersToGroupWidgetStateful> createState() => _AddUsersToGroupWidgetStatefulState();
}

class _AddUsersToGroupWidgetStatefulState extends State<_AddUsersToGroupWidgetStateful> with LifecycleListenerMixin{
  late AddUsersToGroupController controller;

  @override
  void initState(){
    super.initState();
    controller = AddUsersToGroupController(
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
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Add Users'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: controller.selectedUsersID,
            builder: (context, selectedUsersID, child){
              return Padding(
                padding: EdgeInsets.symmetric(vertical: kToolbarHeight * 0.15, horizontal: getScreenWidth() * 0.025),
                child: CustomButton(
                  width: getScreenWidth() * 0.25,
                  height: kToolbarHeight, 
                  color: Colors.red, 
                  text: 'Continue',
                  onTapped: selectedUsersID.isNotEmpty ? () => controller.addUsersToGroup() : null,
                  setBorderRadius: true,
                  prefix: null,
                  loading: false,
                ),
              );
            }
          )
        ]
      ),
      body: ListView(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([
              controller.isSearching,
              controller.verifySearchedFormat
            ]),
            builder: (context, child){
              bool isSearchingValue = controller.isSearching.value;
              bool searchedVerified = controller.verifySearchedFormat.value;
              return SizedBox(
                width: getScreenWidth(),
                height: getScreenHeight() * 0.075,
                child: TextField(
                  controller: controller.searchedController,
                  decoration: generateSearchTextFieldDecoration(
                    'user', Icons.search,
                    !isSearchingValue && searchedVerified ? () => controller.searchUsers(false) : null
                  ),
                )
              );
            },
          ),
          ListenableBuilder(
            listenable: Listenable.merge([
              controller.users,
              controller.selectedUsersID
            ]),
            builder: (context, child){
              List<String> usersList = controller.users.value;
              List<String> selectedUsersID = controller.selectedUsersID.value;
              return Column(
                children: [
                  for(int i = 0; i < usersList.length; i++)
                  InkWell(
                    splashFactory: InkRipple.splashFactory,
                    child: GestureDetector(
                      onTap: (){
                        controller.toggleSelectUser(usersList[i], appStateRepo.usersDataNotifiers.value[usersList[i]]!.notifier.value.name);
                      },
                      child: Container(
                        color: selectedUsersID.contains(usersList[i]) ? Colors.grey.withOpacity(0.5) : Colors.transparent,
                        child: CustomSimpleUserDataWidget(
                          userData: appStateRepo.usersDataNotifiers.value[usersList[i]]!.notifier.value,
                          key: UniqueKey()
                        )
                      )
                    )
                  )
                ],
              );
            },
          )
        ],
      ),
    );
  }
}