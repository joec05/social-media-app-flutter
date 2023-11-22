class DisplayCommentDataClass{
  final String sender;
  final String commentID;

  DisplayCommentDataClass(this.sender, this.commentID);
  @override
  bool operator == (Object other) =>
  identical(this, other) || (other is DisplayCommentDataClass && other.commentID == commentID && other.sender == sender);
}