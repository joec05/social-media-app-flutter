import 'package:social_media_app/global_files.dart';

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

int postDraftTextFieldMinLines = 1;

int postDraftTextFieldMaxLines = 15;

int messageDraftTextFieldMinLines = 1;

int messageDraftTextFieldMaxLines = 10;

double animateToTopMinHeight = getScreenHeight();