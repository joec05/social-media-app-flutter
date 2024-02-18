import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageController {
  final storage = const FlutterSecureStorage();
  String userStateKey = 'user_state';

  void writeUserState(String? lifecycleState, String? time) async{
    Map currentUserDataMap = {
      'last_lifecycle_state': lifecycleState,
      'last_lifecycle_time': time,
    };
    storage.write(
      key: userStateKey, 
      value: jsonEncode(currentUserDataMap)
    );
  }

  Future<Map> readUserState() async{
    String? userState = await storage.read(key: userStateKey); 
    if(userState == null){
      return {
        'last_lifecycle_state': null,
        'last_lifecycle_time': null
      };
    }else{
      return jsonDecode(userState); 
    }
  }
}

final SecureStorageController secureStorageController = SecureStorageController();