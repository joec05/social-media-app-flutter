/// Default duration in ms to delay before navigating
var navigatorDelayTime = 500;

/// Default duration in ms to delay before performing a range of actions such as running a function
var actionDelayTime = 350;

/// If the time difference between the user's last activity in the app and now, in minutes, exceeded 
/// this number, the user will be automatically navigated back to the main page when the user re-opens
/// the app. This only happens if the user hasn't closed the app at all.
int timeDifferenceToMainPage = 60;

/// If the time difference between the user's last activity in the app and now, in minutes, exceeded 
/// this number, the user will be automatically logged out when the user re-opens
/// the app and will have to re-login. This only happens if the user hasn't closed the app at all.
int timeDifferenceToLogOut = 25 * 60;