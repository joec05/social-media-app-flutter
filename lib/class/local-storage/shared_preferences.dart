import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/constants/global_variables.dart';

class SharedPreferencesClass{
  Future<SharedPreferences> getSharedPreferences() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  void updateCurrentUser(String currentID, AppLifecycleState appLifecycleState) async{
    Map currentUserDataMap = {
      'user_id': currentID,
      'last_lifecycle_state': appLifecycleState.name,
      'last_lifecycle_time': DateTime.now().toIso8601String()
    };
    SharedPreferences prefs = await getSharedPreferences();
    prefs.setString(lifecycleDataKey, jsonEncode(currentUserDataMap));
  }

  void resetCurrentUser() async{
    Map currentUserDataMap = {
      'user_id': '',
      'last_lifecycle_state': '',
      'last_lifecycle_time': ''
    };
    SharedPreferences prefs = await getSharedPreferences();
    prefs.setString(lifecycleDataKey, jsonEncode(currentUserDataMap));
  }

  Future<Map> fetchCurrentUser() async{
    SharedPreferences prefs = await getSharedPreferences();
    String? currentUser = prefs.getString(lifecycleDataKey); 
    if(currentUser == null){
      return {
        'user_id': '',
        'last_lifecycle_state': '',
        'last_lifecycle_time': ''
      };
    }else{
      return jsonDecode(currentUser); 
    }
  }
}