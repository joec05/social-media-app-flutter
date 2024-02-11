import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SearchChatUsersWidget extends StatelessWidget {
  const SearchChatUsersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SearchChatUsersWidgetStateful();
  }
}

class _SearchChatUsersWidgetStateful extends StatefulWidget {
  const _SearchChatUsersWidgetStateful();

  @override
  State<_SearchChatUsersWidgetStateful> createState() => __SearchChatUsersWidgetStatefulState();
}

class __SearchChatUsersWidgetStatefulState extends State<_SearchChatUsersWidgetStateful> with LifecycleListenerMixin{
  late SearchChatUsersController controller;

  @override
  void initState(){
    super.initState();
    controller = SearchChatUsersController(context);
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
        title: const Text('Message Users'), 
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
                  width: getScreenWidth() * 0.25, height: kToolbarHeight, 
                  buttonColor: Colors.red, buttonText: 'Continue',
                  onTapped: selectedUsersID.isNotEmpty ? () => controller.navigateToChat() : null,
                  setBorderRadius: true
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
                  decoration: generateSearchTextFieldDecoration('user', Icons.search, !isSearchingValue && searchedVerified ?
                    () => controller.searchUsers(false) : null),
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
                    onTap: (){
                    },
                    child: GestureDetector(
                      onTap: () => controller.toggleSelectUser(usersList[i]),
                      child: Container(
                        color: selectedUsersID.contains(usersList[i]) ? Colors.grey.withOpacity(0.5) : Colors.transparent,
                        child: CustomSimpleUserDataWidget(
                          userData: appStateClass.usersDataNotifiers.value[usersList[i]]!.notifier.value,
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