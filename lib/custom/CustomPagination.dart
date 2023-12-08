import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalEnums.dart';

class LoadMoreBottom extends StatefulWidget {
  final VoidCallback loadMore;
  final CustomScrollView child;
  final Key customKey = const Key('load_more_page');
  final PaginationStatus status;
  final Future Function()? refresh;
  final bool addBottomSpace;

  const LoadMoreBottom({Key? key, required this.child, required this.loadMore, required this.status, required this.refresh, required this.addBottomSpace}): super(key: key);

  @override
  LoadMoreBottomState createState() => LoadMoreBottomState();
}

class LoadMoreBottomState extends State<LoadMoreBottom>{
  ValueNotifier<bool> setLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    setLoading.dispose();
  }

  void _scrollListener() {
    if(mounted){
      setLoading.value = true;
    }
    widget.loadMore();
    if(mounted){
      setLoading.value = false;
    }
  }

  Widget buildLoaded(){
    return Center(
      child: widget.addBottomSpace ? SizedBox(
        width: 30,
        height: 30,
        child: Container()
      ) : null
    );
  }

  Widget buildLoading(){
    return Center(
      child: SizedBox(
        width: 30,
        height: 30 ,
        child: Transform.scale(
          scale: 0.5,
          child: const CircularProgressIndicator(
            strokeWidth: 5
          ),
        )
      )
    );
  }

  Widget buildStatus(PaginationStatus status){
    if(status == PaginationStatus.loaded){
      return buildLoaded();
    }else if(status == PaginationStatus.loading){
      return buildLoading();
    }else if(status == PaginationStatus.error){
      return Container();
    }else{
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    dynamic check = widget.child.slivers.elementAt(widget.child.slivers.length - 1);

    if (check is SliverSafeArea && check.key == widget.customKey) {
      widget.child.slivers.removeLast();
    }

    widget.child.slivers.add(
      SliverSafeArea(
        key: widget.customKey,
        top: false,
        left: false,
        right: false,
        sliver: SliverToBoxAdapter(
          child: buildStatus(widget.status),
        ),
      ),
    );

    return NotificationListener<ScrollEndNotification>(
      onNotification: (ScrollEndNotification notification) {
        double currentExtent = notification.metrics.pixels;
        double maxExtent = notification.metrics.maxScrollExtent;
        if (widget.status == PaginationStatus.loaded) {
          if (currentExtent >= maxExtent) {
            _scrollListener();
            return true;
          }
        }
        return false;
      },
      child: RefreshIndicator(
        notificationPredicate: widget.refresh != null ? (_) => true : (_) => false,
        onRefresh: widget.refresh != null ? widget.refresh! : ()async{},
        child: widget.child
      )
    );
  }

}