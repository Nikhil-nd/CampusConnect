import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../admin/admin_panel_screen.dart';
import '../chat/chat_list_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<UserModel?>(
        stream: firestore.watchCurrentUser(),
        builder: (BuildContext context, AsyncSnapshot<UserModel?> snapshot) {
          final UserModel? user = snapshot.data;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user.name),
                  subtitle: Text('${user.branch} - Year ${user.year}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Reputation'),
                  subtitle: Text('${user.reputation}'),
                ),
              ),
              const Card(
                child: ListTile(
                  title: Text('My Listings'),
                  subtitle: Text('Marketplace + Jobs + Events activity'),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChatListScreen()));
                },
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Open Chats'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await firestore.addRating(sellerId: user.uid, rating: 5);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Demo rating submitted.')),
                    );
                  }
                },
                icon: const Icon(Icons.star_outline),
                label: const Text('Rate Seller (Demo)'),
              ),
              const SizedBox(height: 8),
              if (user.isAdmin)
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AdminPanelScreen()),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Open Admin Panel'),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          );
        },
      ),
    );
  }
}
