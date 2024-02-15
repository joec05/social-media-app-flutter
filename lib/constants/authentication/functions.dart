/// Returns true if the given email is in a proper format
bool checkEmailValid(String email){
  return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
  .hasMatch(email);
}

/// Returns true if the given username is in a proper format
bool checkUsernameValid(username){
  var usernamePattern = RegExp(r"^(?=.*[a-zA-Z])[\w\d_]+$");
  return usernamePattern.hasMatch(username);
}