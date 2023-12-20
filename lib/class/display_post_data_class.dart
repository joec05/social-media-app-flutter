// ignore_for_file: hash_and_equals

class DisplayPostDataClass{
  final String sender;
  final String postID;

  DisplayPostDataClass(this.sender, this.postID);

  @override
  bool operator == (Object other) =>
  identical(this, other) || (other is DisplayPostDataClass && other.postID == postID && other.sender == sender);
}