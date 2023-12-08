import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/DrawerNavigator.dart';
import 'package:social_media_app/Explore.dart';
import 'package:social_media_app/Notifications.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'Feed.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'styles/AppStyles.dart';

class MainPageWidget extends StatelessWidget {
  const MainPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MainPageWidgetStateful();
  }
}

class _MainPageWidgetStateful extends StatefulWidget {
  const _MainPageWidgetStateful();

  @override
  State<_MainPageWidgetStateful> createState() => __MainPageWidgetStatefulState();
}

class __MainPageWidgetStatefulState extends State<_MainPageWidgetStateful> with LifecycleListenerMixin{
  ValueNotifier<int> selectedIndexValue = ValueNotifier(0);
  final PageController _pageController = PageController(initialPage: 0, keepPage: true, );
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override void initState(){
    super.initState();
    initLifecycleListener(changeBottomNavIndex: resetBottomNavIndex, scaffoldKey: scaffoldKey);
  }

  void resetBottomNavIndex(){
    _pageController.jumpToPage(0);
  }

  @override void dispose(){
    super.dispose();
    selectedIndexValue.dispose();
    _pageController.dispose();
  }

  void onPageChanged(newIndex){
    if(mounted){
      selectedIndexValue.value = newIndex;
    }
  }

  final List<Widget> widgetOptions = <Widget>[
    const FeedWidget(), const ExploreWidget(), const NotificationsWidget()
  ];

  PreferredSizeWidget setAppBar(index){
    if(index == 0){
      return AppBar(
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        title: const Text('Feed'), titleSpacing: defaultAppBarTitleSpacing,
      );
    }else if(index == 1){
      return AppBar(
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        title: const Text('Explore'), titleSpacing: defaultAppBarTitleSpacing,
      );
    }else if(index == 2){
      return AppBar(
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        title: const Text('Notifications'), titleSpacing: defaultAppBarTitleSpacing,
      );
    }
    return AppBar();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedIndexValue,
      builder: (BuildContext context, int selectedIndexValue, Widget? child) {
        return Scaffold(
          key: scaffoldKey,
          drawerEdgeDragWidth: 0.85 * getScreenWidth(),
          onDrawerChanged: (isOpened) {
            if(isOpened){
            }
          },
          appBar: setAppBar(selectedIndexValue),
          body: PageView(
            controller: _pageController,
            onPageChanged: onPageChanged,
            children: widgetOptions,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              boxShadow: [                                                               
                BoxShadow(color: Colors.white, spreadRadius: 0, blurRadius: 10),
              ],
            ),
            child:SizedBox(
            width: 0.7 * getScreenWidth(),
            child: ClipRRect(                                                            
              borderRadius: const BorderRadius.all(Radius.circular(15)),                                                     
              child: BottomNavigationBar(
                key: UniqueKey(),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.house, size: 25),
                    label: 'Feed',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.magnifyingGlass, size: 25),
                    label: 'Explore',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.solidBell, size: 25),
                    label: 'Notifications',
                  ),
                ],
                currentIndex: selectedIndexValue,
                onTap: ((index) {
                  _pageController.jumpToPage(index);
                })
              ),
            ),
            )
          ),
          drawer: DrawerNavigator(key: UniqueKey(), parentContext: context)
        );
      }
    );
  }
}
