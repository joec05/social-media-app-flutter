import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/mixin/lifecycle_listener.dart';
import 'package:social_media_app/screens/search/searched_comments.dart';
import 'package:social_media_app/screens/search/searched_posts.dart';
import 'package:social_media_app/screens/search/searched_users.dart';
import 'package:social_media_app/styles/app_styles.dart';

class SearchedWidget extends StatelessWidget {
  final String searchedText;
  const SearchedWidget({super.key, required this.searchedText});

  @override
  Widget build(BuildContext context) {
    return _SearchedWidgetStateful(searchedText: searchedText);
  }
}

class _SearchedWidgetStateful extends StatefulWidget {
  final String searchedText;
  const _SearchedWidgetStateful({required this.searchedText});

  @override
  State<_SearchedWidgetStateful> createState() => _SearchedWidgetStatefulState();
}

var dio = Dio();

class _SearchedWidgetStatefulState extends State<_SearchedWidgetStateful> with SingleTickerProviderStateMixin, LifecycleListenerMixin{
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  late String searchedText;

  @override
  void initState(){
    super.initState();
    searchedText = widget.searchedText;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override void dispose(){
    super.dispose();
    _tabController.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Search Results'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: Stack(
        children: [
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, bool f) {
              return <Widget>[
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverAppBar(
                    floating: true, 
                    expandedHeight: 50,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    bottom: TabBar(
                      onTap: (selectedIndex) {
                      },
                      isScrollable: false,
                      controller: _tabController,
                      labelColor: Colors.white,
                      indicatorColor: Colors.orange,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 3.0,
                      unselectedLabelColor: Colors.white,
                      tabs: const [
                        Tab(text: 'Posts'),
                        Tab(text: 'Replies'),
                        Tab(text: 'Users')
                      ],                           
                    )
                  )
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                SearchedPostsWidget(searchedText: searchedText, key: UniqueKey(), absorberContext: context), 
                SearchedCommentsWidget(searchedText: searchedText, key: UniqueKey(), absorberContext: context),
                SearchedUsersWidget(searchedText: searchedText, key: UniqueKey(), absorberContext: context)
              ]
            )
          )
        ]
      ),
    );
  }
}
