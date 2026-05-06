import 'package:flutter/material.dart';

import '../../widgets/campus_hero_header.dart';
import '../../widgets/feed_card.dart';
import '../chat/chat_list_screen.dart';
import '../lostfound/lostfound_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Feed')),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isWide = constraints.maxWidth >= 700;
          const EdgeInsets padding = EdgeInsets.all(16);

          final List<FeedCard> cards = <FeedCard>[
            FeedCard(
              title: 'Hackathon Week is Live',
              subtitle: 'Register now for coding marathon and prizes.',
              icon: Icons.event,
              onTap: () {},
            ),
            FeedCard(
              title: 'New Marketplace Listings',
              subtitle: 'See new notes, books and gadgets posted today.',
              icon: Icons.storefront,
              onTap: () {},
            ),
            FeedCard(
              title: 'Lost and Found Alerts',
              subtitle: 'Wallet and keychain reported near library.',
              icon: Icons.search,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LostFoundScreen()));
              },
            ),
            FeedCard(
              title: 'Student DMs',
              subtitle: 'Open your direct chats with peers.',
              icon: Icons.chat_bubble_outline,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChatListScreen()));
              },
            ),
          ];

          Future<void> refreshFeed() async {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feed refreshed')),
              );
            }
          }

          final Widget content = isWide
              ? GridView.count(
                  padding: EdgeInsets.zero,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: cards,
                )
              : Column(
                  children: cards
                      .map(
                        (FeedCard card) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: card,
                        ),
                      )
                      .toList(),
                );

          return RefreshIndicator(
            onRefresh: refreshFeed,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const CampusHeroHeader(),
                  const SizedBox(height: 20),
                  Text(
                    'Highlights',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  content,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
