import 'package:social_media_app/global_files.dart';

/// A map which stores the maximum length of profile input values in which will be applied 
/// to the TextField widget
Map profileInputMaxLimit = {
  'name': 30,
  'username': 15, 
  'password': 30,
  'hashtagText': 30,
  'bio': 350,
};

/// A map which stores the minimum length of profile input values in which will be applied 
/// to the TextField widget
Map profileInputMinLimit = {
  'username': 5,
  'password': 10
};

/// A map which stores the maximum length of group profile input values in which will be applied 
/// to the TextField widget
Map groupProfileInputMaxLimit = {
  'name': 50,
  'description': 200
};

/// Maximum length of a hashtag
int hashtagTextInputMaxLimit = 25;

/// Maximum length of a message
int messageCharacterMaxLimit = 100;

/// Maximum length of a post or a comment
int maxPostWordLimit = 300;

/// Maximum amount of media that can be attached with a post or a comment
int maxMediaCount = 2;

/// Maximum amount of media that can be attached with a message
int maxMessageMediaCount = 1;

/// Maximum amount of notifications that can be fetched during pagination in a single page
int notificationsPaginationLimit = 5;

/// Maximum amount of follow requests that can be fetched during pagination in a single page
int followRequestsPaginationLimit = 5;

/// Maximum amount of posts or comments that can be fetched during pagination in a single page
int postsPaginationLimit = 5;

/// Maximum amount of users that can be fetched during pagination in a single page
int usersPaginationLimit = 5;

/// Maximum amount of messages that can be fetched during pagination in a single page
int messagesPaginationLimit = 10;

/// Maximum amount of posts that the API can fetch in a single page
int postsServerFetchLimit = 100;

/// Maximum amount of users that the API can fetch in a single page
int usersServerFetchLimit = 100;

/// Maximum amount of notifications that the API can fetch in a single page
int notificationsServerFetchLimit = 100;

/// Maximum amount of chats that the API can fetch in a single page
int chatsServerFetchLimit = 30;

/// Maximum amount of messages that the API can fetch in a single page
int messagesServerFetchLimit = 50;

/// Maximum amount of users that the API can fetch when the user searches for another user to tag in a post/comment
int searchTagUsersFetchLimit = 20;

/// Maximum amount of users that the API can fetch when the user searches for another user to message to
int searchChatUsersFetchLimit = 20;

/// Minimum amount of lines for a post or comment draft. Applied to the TextField widget.
int postDraftTextFieldMinLines = 1;

/// Maximum amount of lines for a post or comment draft. Applied to the TextField widget.
int postDraftTextFieldMaxLines = 15;

/// Minimum amount of lines for a message draft. Applied to the TextField widget.
int messageDraftTextFieldMinLines = 1;

/// Maximum amount of lines for a message draft. Applied to the TextField widget.
int messageDraftTextFieldMaxLines = 10;

/// Minimum offset the user needs to scroll in a single page in order for the floating icon to appear.
/// The floating icon can be either a top / bottom arrow depending on the page itself, and when pressed, 
/// will automatically navigate the user to either top or bottom depending on the arrow icon
double animateToTopMinHeight = getScreenHeight();