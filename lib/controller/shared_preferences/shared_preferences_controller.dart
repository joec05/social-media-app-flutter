import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesController {
  late SharedPreferences prefs;
  String onboardingDisplayedKey = 'onboarding_displayed';

  void initializeController() async{
    prefs = await SharedPreferences.getInstance();
  }

  void setOnboardingDisplayed(bool displayed){
    prefs.setBool(onboardingDisplayedKey, displayed);
  }

  bool? getOnboardingDisplayed(){
    bool? displayed = prefs.getBool(onboardingDisplayedKey);
    return displayed;
  }
}

final SharedPreferencesController sharedPreferencesController = SharedPreferencesController();