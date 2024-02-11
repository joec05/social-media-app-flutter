import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SearchTagUsersWidget extends StatelessWidget {
  final Function onUserIsSelected;
  const SearchTagUsersWidget({super.key, required this.onUserIsSelected});

  @override
  Widget build(BuildContext context) {
    return _SearchTagUsersWidgetStateful(onUserIsSelected: onUserIsSelected);
  }
}

class _SearchTagUsersWidgetStateful extends StatefulWidget {
  final Function onUserIsSelected;
  const _SearchTagUsersWidgetStateful({required this.onUserIsSelected});

  @override
  State<_SearchTagUsersWidgetStateful> createState() => __SearchTagUsersWidgetStatefulState();
}

class __SearchTagUsersWidgetStatefulState extends State<_SearchTagUsersWidgetStateful> with LifecycleListenerMixin{
  late SearchTagUsersController controller;

  @override
  void initState(){
    super.initState();
    controller = SearchTagUsersController(context);
    controller.initializeController();
  }

  @override void dispose(){
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 56, 54, 54),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0)
        )
      ),
      child: Column(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: getScreenHeight() * 0.015),
              Container(
                height: getScreenHeight() * 0.01,
                width: getScreenWidth() * 0.15,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(10))
                )
              ),
              SizedBox(height: getScreenHeight() * 0.015),
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
              )
            ]
          ),
          Flexible(
            child: SingleChildScrollView(
              child: ListenableBuilder(
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
                          onTap: () => controller.toggleSelectUser(
                            usersList[i], 
                            appStateClass.usersDataNotifiers.value[usersList[i]]!.notifier.value.username
                          ),
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
            ),
          ),
          Column(
            children: [
              ValueListenableBuilder(
                valueListenable: controller.selectedUsersID,
                builder: (context, selectedUsersID, child){
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.025, horizontal: getScreenWidth() * 0.025),
                    child: CustomButton(
                      width: double.infinity, height: getScreenHeight() * 0.08,
                      buttonColor: Colors.red, buttonText: 'Continue',
                      onTapped: selectedUsersID.isNotEmpty ? () => controller.continueTag(
                        widget.onUserIsSelected(
                          controller.selectedUsersUsername.value, 
                          controller.selectedUsersID.value
                        )
                      ) : null,
                      setBorderRadius: true
                    ),
                  );
                }
              )
            ]
          )
        ],
      ),
    );
  }
}