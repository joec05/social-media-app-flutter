/// Enum to store actions in a private chat
enum PrivateMessageActions{
  deleteChat
}

/// Enum to store actions in a group chat
enum GroupMessageActions{
  deleteChat
}

/// This is used specifically when the user deletes a chat and gets navigated back automatically
/// Every time the user deletes a chat this enum is used to confirm if the chat should be deleted