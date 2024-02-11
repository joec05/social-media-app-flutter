bool checkEmailValid(email){
  return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
  .hasMatch(email);
}

bool checkUsernameValid(username){
  var usernamePattern = RegExp(r"^(?=.*[a-zA-Z])[\w\d_]+$");
  return usernamePattern.hasMatch(username);
}