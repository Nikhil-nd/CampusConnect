import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/nav_provider.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../events/events_screen.dart';
import '../home/home_screen.dart';
import '../jobs/jobs_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../profile/profile_screen.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NavProvider nav = context.watch<NavProvider>();

    final List<Widget> pages = <Widget>[
      const HomeScreen(),
      const MarketplaceScreen(),
      const EventsScreen(),
      const JobsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: nav.index, children: pages),
      bottomNavigationBar: AppBottomNavBar(
        index: nav.index,
        onTap: context.read<NavProvider>().setIndex,
      ),
    );
  }
}
