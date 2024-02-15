import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesController {
  late SharedPreferences prefs;
  String onboardingDisplayedKey = 'onboarding_displayed';
  String appThemeKey = 'app_theme';

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

  void setAppTheme(String theme){
    prefs.setString(appThemeKey, theme);
  }

  String? getAppTheme(){
    String? themeStr = prefs.getString(appThemeKey);
    return themeStr;
  }
}

final SharedPreferencesController sharedPreferencesController = SharedPreferencesController();