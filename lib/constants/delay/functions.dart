/// A function which accepts another function and a duration in milliseconds as an argument
/// The function will first start by delaying by the given milliseconds, and after that run the given function
/// Typically useful for drawers or dialogs where a delayed time is needed to pop them, as well as InkWell widgets to display the splash effect before running the given function
void runDelay(Function func, int duration) async{
  Future.delayed(Duration(milliseconds: duration), (){}).then((value){
    func();
  });
}