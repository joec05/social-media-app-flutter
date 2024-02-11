import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';


class ProfileWithUsernameController {
  BuildContext context;
  String username;
  TabController tabController;
  ValueNotifier<String> userID = ValueNotifier('');
  ValueNotifier<bool> isLoading = ValueNotifier(true);
  ValueNotifier<UniqueKey?> profilePostsWidgetUniqueKey = ValueNotifier(null);
  ValueNotifier<UniqueKey?> profileRepliesWidgetUniqueKey = ValueNotifier(null);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  ProfileWithUsernameController(
    this.context,
    this.username,
    this.tabController
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchProfileDataWithUsername(), actionDelayTime);
    scrollController.addListener(() {
      if(mounted){
        if(scrollController.position.pixels > animateToTopMinHeight){
          if(!displayFloatingBtn.value){
            displayFloatingBtn.value = true;
          }
        }else{
          if(displayFloatingBtn.value){
            displayFloatingBtn.value = false;
          }
        }
      }
    });
  }

  void dispose(){
    tabController.dispose();
    isLoading.dispose();
    userID.dispose();
    profilePostsWidgetUniqueKey.dispose();
    profileRepliesWidgetUniqueKey.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchProfileDataWithUsername() async{
    try {
      if(mounted){
        isLoading.value = true;
        profilePostsWidgetUniqueKey.value = UniqueKey();
        profileRepliesWidgetUniqueKey.value = UniqueKey();
        String stringified = jsonEncode({
          'username': username,
          'currentID': appStateClass.currentID,
        });
        var res = await dio.get('$serverDomainAddress/users/fetchUserProfileSocialsWithUsername', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            Map userProfileData = res.data['userProfileData'];
            if(userProfileData['code'] == 0){
            }else{
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              Map userSocialsData = res.data['userSocialsData'];
              UserSocialClass userSocialClass = UserSocialClass.fromMap(userSocialsData);
              if(mounted){
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
                userID.value = userProfileData['user_id'];
              }
            }
          }
          if(mounted){
            isLoading.value = false;
          }
        }
      }
    } on Exception catch (e) {
      
    }
  }
}