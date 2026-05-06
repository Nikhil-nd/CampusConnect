import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_router.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.watchUserChats(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> chats = snapshot.data!.docs;
          if (chats.isEmpty) {
            return const EmptyState(title: 'No chats yet. Start a conversation from profile or listings.');
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (BuildContext context, int index) {
              final QueryDocumentSnapshot<Map<String, dynamic>> chat = chats[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                title: Text(chat.id),
                subtitle: Text(chat.data()['lastMessage'] as String? ?? ''),
                onTap: () => Navigator.pushNamed(context, AppRouter.chat, arguments: chat.id),
              );
            },
          );
        },
      ),
    );
  }
}
