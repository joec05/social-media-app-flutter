// ignore_for_file: non_constant_identifier_names

import 'package:social_media_app/constants/global_functions.dart';

String IP = '192.168.1.153';

String PORT = '5001';

String lifecycleDataKey = 'lifecycle_data_state';

int timeDifferenceToMainPage = 1;

int timeDifferenceToLogOut = 3;

Map storageBucketIDs = {
  'image': '6572866b8a6c2cc7670c',
};

String appWriteUserID = '648336f2bc96857e5f14';

Map profileInputMaxLimit = {
  'name': 30,
  'username': 15,
  'password': 30,
  'hashtagText': 30,
  'bio': 350,
};

Map profileInputMinLimit = {
  'username': 5,
  'password': 10
};

Map groupProfileInputMaxLimit = {
  'name': 50,
  'description': 200
};

int hashtagTextInputMaxLimit = 25;

int messageCharacterMaxLimit = 100;

RegExp textDisplayUserTagRegex = RegExp(r"\B@[a-zA-Z0-9_]{1," + profileInputMaxLimit['username'].toString() + r"}(?<=\w)");

RegExp atTypedDisplayUserListRegex = RegExp("(?<![a-zA-Z0-9_])@");

RegExp textDisplayHashtagRegex = RegExp(r"\B#[a-zA-Z0-9_]{1," + profileInputMaxLimit['hashtagText'].toString() + r"}(?<=\w)");

RegExp atTypedDisplayHashtagListRegex = RegExp("(?<![a-zA-Z0-9_])#");

RegExp isLinkRegex = RegExp(r'^(?:(?:https?|ftp):\/\/)?[\w-]+(\.[\w-]+)+[\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-]$');

RegExp isLinkRegexTyped = RegExp(r'(?:^|\s)(?:(?:https?|ftp):\/\/)?[\w-]+(\.[\w-]+)+[\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-](?:$|\s)');

int maxPostWordLimit = 300;

int maxMediaCount = 2;

int maxMessageMediaCount = 1;

int notificationsPaginationLimit = 5;

int followRequestsPaginationLimit = 5;

int postsPaginationLimit = 5;

int usersPaginationLimit = 5;

int postsServerFetchLimit = 100;

int usersServerFetchLimit = 100;

int notificationsServerFetchLimit = 100;

int chatsServerFetchLimit = 30;

int messagesPaginationLimit = 10;

int messagesServerFetchLimit = 50;

int searchTagUsersFetchLimit = 20;

int searchChatUsersFetchLimit = 20;

String defaultUserProfilePicLink = 'https://github.com/joec05/files/blob/main/social_media_app/defaultUserProfilePicLink.png?raw=true';

String defaultGroupChatProfilePicLink = 'https://as2.ftcdn.net/v2/jpg/03/13/82/51/1000_F_313825184_EpuEFYiODvG1lvqfKN2uIVAceAV5T0OX.jpg';

String defaultWebsiteCardImageLink = 'https://github.com/joec05/files/blob/main/social_media_app/websiteCardLinkLogo.jpg?raw=true';

int postDraftTextFieldMinLines = 1;

int postDraftTextFieldMaxLines = 15;

int messageDraftTextFieldMinLines = 1;

int messageDraftTextFieldMaxLines = 10;

var navigatorDelayTime = 500;

var actionDelayTime = 350;

//String serverDomainAddress = 'https://flutter-social-media-app.serveo.net';

String serverDomainAddress = 'http://$IP:$PORT';

double animateToTopMinHeight = getScreenHeight();