class DialogAction {
  String text;
  Function() onPressed;
  bool danger;

  DialogAction(
    this.text,
    this.onPressed,
    this.danger
  );
}