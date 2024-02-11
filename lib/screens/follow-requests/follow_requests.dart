import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class FollowRequestsWidget extends StatelessWidget {
  const FollowRequestsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FollowRequestsWidgetStateful();
  }
}

class _FollowRequestsWidgetStateful extends StatefulWidget {
  const _FollowRequestsWidgetStateful();

  @override
  State<_FollowRequestsWidgetStateful> createState() => _FollowRequestsWidgetStatefulState();
}

class _FollowRequestsWidgetStatefulState extends State<_FollowRequestsWidgetStateful> with SingleTickerProviderStateMixin, LifecycleListenerMixin{
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Follow Requests'), 
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
                SliverToBoxAdapter(
                  child: Container(
                    
                  ),
                ),
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
                        Tab(text: 'Requests From Me'),
                        Tab(text: 'Requests To Me'),
                      ],                           
                    )
                  )
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                FollowRequestsFromWidget(absorberContext: context),
                FollowRequestsToWidget(absorberContext: context)
              ]
            )
          )
        ]
      ),
    );
  }
}
