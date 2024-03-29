import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/global_files.dart';

class DrawerNavigator extends StatelessWidget {
  final BuildContext parentContext;
  const DrawerNavigator({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return _DrawerNavigatorStateful(parentContext: parentContext);
  }
}

class _DrawerNavigatorStateful extends StatefulWidget {
  final BuildContext parentContext;
  const _DrawerNavigatorStateful({required this.parentContext});

  @override
  State<_DrawerNavigatorStateful> createState() => __DrawerNavigatorStatefulState();
}

class __DrawerNavigatorStatefulState extends State<_DrawerNavigatorStateful> with LifecycleListenerMixin{
  late BuildContext parentContext;

  @override
  void initState() {
    super.initState();
    parentContext = widget.parentContext;
  }

  @override
  void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            title: Container(
              margin: EdgeInsets.only(top: getScreenHeight() * 0.05),
              width:  0.85 * getScreenWidth(),
              height: getScreenHeight() * 0.2,
              child: appStateRepo.usersDataNotifiers.value[appStateRepo.currentID] != null ?
                ValueListenableBuilder(
                  valueListenable: appStateRepo.usersDataNotifiers.value[appStateRepo.currentID]!.notifier,
                  builder: (context, UserDataClass userData, child){
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: (){
                                  runDelay((){
                                    if(mounted){
                                      Navigator.pop(context);
                                    }
                                    runDelay(() => Navigator.push(
                                      parentContext,
                                      SliderRightToLeftRoute(
                                        page: ProfilePageWidget(userID: userData.userID)
                                      )
                                    ), navigatorDelayTime);
                                  }, navigatorDelayTime);
                                },
                                child: Container(
                                  width: getScreenWidth() * 0.15, height: getScreenWidth() * 0.15,
                                  decoration: BoxDecoration(
                                    border: Border.all(width: 2),
                                    borderRadius: BorderRadius.circular(100),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        userData.profilePicLink
                                      ), fit: BoxFit.fill
                                    )
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Flexible(child: Text(StringEllipsis.convertToEllipsis(userData.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.bold))),
                                              userData.verified && !userData.suspended && !userData.deleted ?
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: iconsBesideNameProfileMargin
                                                    ),
                                                    Icon(Icons.verified_rounded, size: verifiedIconProfileWidgetSize),
                                                  ]
                                                )
                                              : Container(),
                                              userData.private && !userData.suspended && !userData.deleted ?
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: iconsBesideNameProfileMargin
                                                    ),
                                                    Icon(FontAwesomeIcons.lock, size: lockIconProfileWidgetSize),
                                                  ],
                                                )
                                              : Container(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: getScreenHeight() * 0.0015
                                    ),
                                    Text(userData.suspended || userData.deleted ? '@' : '@${userData.username}', style: TextStyle(fontSize: defaultTextFontSize, color: Colors.lightBlue))
                                  ],
                                ),
                              ),
                              Divider(
                                color: Theme.of(context).dividerColor,
                                height: 2.5, 
                                thickness: 1
                              ),
                            ],
                          ),
                        ),
                      ]
                    );
                  }
                )
              : loadingPageWidget()
            )
          ),
          ListTile(
            title: SizedBox(
              width:  0.85 * getScreenWidth(),
              height: getScreenHeight() * 0.07,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FontAwesomeIcons.pencil, size: 20),
                      SizedBox(width: getScreenWidth() * 0.05),
                      Text('Write Post', style: TextStyle(fontSize: defaultTextFontSize)),
                    ],
                  )
                ]
              ),
            ),
            onTap: () {
              runDelay((){
                if(mounted){
                  Navigator.pop(context);
                }
                runDelay(() => Navigator.push(
                  parentContext,
                  SliderRightToLeftRoute(
                    page: const WritePostWidget()
                  )
                ), navigatorDelayTime);
              }, navigatorDelayTime);
            },
          ),
          ListTile(
            title: SizedBox(
              width:  0.85 * getScreenWidth(),
              height: getScreenHeight() * 0.07,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FontAwesomeIcons.message, size: 20),
                      SizedBox(width: getScreenWidth() * 0.05),
                      Text('Chats', style: TextStyle(fontSize: defaultTextFontSize)),
                    ],
                  )
                ]
              ),
            ),
            onTap: () {
              runDelay((){
                if(mounted){
                  Navigator.pop(context);
                }
                runDelay(() => Navigator.pushNamed(parentContext, '/chats-list'), navigatorDelayTime);
              }, navigatorDelayTime);
            }
          ),
          ListTile(
            title: SizedBox(
              width:  0.85 * getScreenWidth(),
              height: getScreenHeight() * 0.07,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FontAwesomeIcons.bookmark, size: 20),
                      SizedBox(width: getScreenWidth() * 0.05),
                      Text('Bookmarks', style: TextStyle(fontSize: defaultTextFontSize)),
                    ],
                  )
                ]
              ),
            ),
            onTap: () {
              runDelay((){
                if(mounted){
                  Navigator.pop(context);
                }
                runDelay(() => Navigator.push(
                  parentContext,
                  SliderRightToLeftRoute(
                    page: ProfilePageBookmarksWidget(userID: appStateRepo.currentID)
                  )
                ), navigatorDelayTime);
              }, navigatorDelayTime);
            }
          ),
          ListTile(
            title: SizedBox(
              width:  0.85 * getScreenWidth(),
              height: getScreenHeight() * 0.07,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FontAwesomeIcons.userPlus, size: 20),
                      SizedBox(width: getScreenWidth() * 0.05),
                      Text('Follow Requests', style: TextStyle(fontSize: defaultTextFontSize)),
                    ],
                  )
                ]
              ),
            ),
            onTap: () {
              runDelay((){
                if(mounted){
                  Navigator.pop(context);
                }
                runDelay(() => Navigator.push(
                  parentContext,
                  SliderRightToLeftRoute(
                    page: const FollowRequestsWidget()
                  )
                ), navigatorDelayTime);
              }, navigatorDelayTime);
            }
          ),
          ListTile(
            title: SizedBox(
              width:  0.85 * getScreenWidth(),
              height: getScreenHeight() * 0.07,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder(
                    valueListenable: appStateRepo.appTheme, 
                    builder: (context, themeValue, child){
                      bool isDark = themeValue == globalTheme.dark;
                      return Row(
                        children: [
                          Icon(
                            isDark ? FontAwesomeIcons.sun : FontAwesomeIcons.moon, 
                            size: 20
                          ),
                          SizedBox(width: getScreenWidth() * 0.05),
                          Text('Switch Theme', style: TextStyle(fontSize: defaultTextFontSize)),
                        ],
                      );
                    }
                  )
                ]
              ),
            ),
            onTap: () {
              runDelay((){
                Navigator.of(context).pop();
                runDelay((){
                  if(appStateRepo.appTheme.value == globalTheme.light) {
                    appStateRepo.appTheme.value = globalTheme.dark;
                    sharedPreferencesController.setAppTheme('dark');
                  }else if(appStateRepo.appTheme.value == globalTheme.dark) {
                    appStateRepo.appTheme.value = globalTheme.light;
                    sharedPreferencesController.setAppTheme('light');
                  }
                }, actionDelayTime);
              }, navigatorDelayTime);
            }
          ),
          ListTile(
            title: SizedBox(
              width:  0.85 * getScreenWidth(),
              height: getScreenHeight() * 0.07,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.logout, size: 25),
                      SizedBox(width: getScreenWidth() * 0.05),
                      Text('Log Out', style: TextStyle(fontSize: defaultTextFontSize)),
                    ],
                  )
                ]
              ),
            ),
            onTap: (){
              runDelay((){
                if(mounted){
                  Navigator.pop(context);
                }
                runDelay(() => logOut(parentContext), actionDelayTime);
              }, navigatorDelayTime);
            },
          ),
          ListTile(
            title: SizedBox(
              width:  0.85 * getScreenWidth(),
              height: getScreenHeight() * 0.07,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FontAwesomeIcons.trash, size: 20),
                      SizedBox(width: getScreenWidth() * 0.05),
                      Text('Delete Account', style: TextStyle(fontSize: defaultTextFontSize)),
                    ],
                  )
                ]
              ),
            ),
            onTap: () {
              runDelay((){
                if(mounted){
                  Navigator.pop(context);
                }
                runDelay(() => verifyDeleteAccount(parentContext), actionDelayTime);
              }, navigatorDelayTime);
            },
          ),
        ],
      ),
    );
  }
}
