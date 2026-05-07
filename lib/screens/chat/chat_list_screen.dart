import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/auth_error_message.dart';
import '../../routes/app_router.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestore = context.read<FirestoreService>();
    final String myId = firestore.currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.watchUserChats(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              title: 'Could not load chats',
              subtitle: firebaseErrorMessage(snapshot.error!),
              icon: Icons.wifi_off_outlined,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> chats =
              snapshot.data!.docs.toList()
                ..sort((QueryDocumentSnapshot<Map<String, dynamic>> a,
                    QueryDocumentSnapshot<Map<String, dynamic>> b) {
                  final Timestamp? ta = a.data()['updatedAt'] as Timestamp?;
                  final Timestamp? tb = b.data()['updatedAt'] as Timestamp?;
                  final int ma = ta?.millisecondsSinceEpoch ?? 0;
                  final int mb = tb?.millisecondsSinceEpoch ?? 0;
                  return mb.compareTo(ma);
                });

          if (chats.isEmpty) {
            return const EmptyState(
              title: 'No chats yet.',
              subtitle:
                  'Start a conversation by tapping the chat icon on any Event, Job, or Lost & Found post.',
              icon: Icons.chat_bubble_outline,
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final QueryDocumentSnapshot<Map<String, dynamic>> chat =
                  chats[index];
              final Map<String, dynamic> data = chat.data();

              // Resolve the other participant's UID from the chat document id (uid1_uid2).
              final List<String> parts = chat.id.split('_');
              final String otherId = parts.length == 2
                  ? (parts[0] == myId ? parts[1] : parts[0])
                  : chat.id;

              final String lastMessage = data['lastMessage'] as String? ?? '';
              final Timestamp? ts = data['updatedAt'] as Timestamp?;
              final String timeLabel =
                  ts != null ? _formatTime(ts.toDate()) : '';

              return _ChatTile(
                otherId: otherId,
                lastMessage: lastMessage,
                timeLabel: timeLabel,
                chatId: chat.id,
                firestore: firestore,
              );
            },
          );
        },
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// A single chat tile that resolves the other user's real name asynchronously.
class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.otherId,
    required this.lastMessage,
    required this.timeLabel,
    required this.chatId,
    required this.firestore,
  });

  final String otherId;
  final String lastMessage;
  final String timeLabel;
  final String chatId;
  final FirestoreService firestore;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: firestore.getUserName(otherId),
      builder: (BuildContext context, AsyncSnapshot<String> nameSnap) {
        // While loading, show the first letter placeholder; real name comes in shortly.
        final String displayName = nameSnap.data ?? '…';
        final String avatarLetter =
            displayName.isNotEmpty && displayName != '…'
                ? displayName[0].toUpperCase()
                : '?';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: nameSnap.hasData
                ? Text(
                    avatarLetter,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
          ),
          title: Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            lastMessage.isEmpty ? 'Tap to start chatting' : lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: timeLabel.isEmpty
              ? null
              : Text(
                  timeLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
          onTap: () =>
              Navigator.pushNamed(context, AppRouter.chat, arguments: chatId),
        );
      },
    );
  }
}
