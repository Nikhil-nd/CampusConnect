import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/auth_error_message.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageCtrl = TextEditingController();

  /// Resolves the display name of the other participant from the chat id.
  Future<String> _resolveOtherName(FirestoreService firestore) async {
    final String myId = firestore.currentUserId;
    final List<String> parts = widget.chatId.split('_');
    final String otherId = parts.length == 2
        ? (parts[0] == myId ? parts[1] : parts[0])
        : widget.chatId;
    return firestore.getUserName(otherId);
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestore = context.read<FirestoreService>();

    if (widget.chatId.trim().isEmpty) {
      return const Scaffold(
        body: EmptyState(
          title: 'Invalid chat',
          subtitle: 'Could not open this chat. Please go back and try again.',
          icon: Icons.chat_bubble_outline,
        ),
      );
    }

    return FutureBuilder<String>(
      future: _resolveOtherName(firestore),
      builder: (BuildContext context, AsyncSnapshot<String> nameSnap) {
        final String otherName = nameSnap.data ?? 'Chat';

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    otherName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: firestore.watchMessages(widget.chatId),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                          snapshot) {
                    if (snapshot.hasError) {
                      return EmptyState(
                        title: 'Could not load messages',
                        subtitle: firebaseErrorMessage(snapshot.error!),
                        icon: Icons.wifi_off_outlined,
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                        messages = snapshot.data!.docs;
                    if (messages.isEmpty) {
                      return const EmptyState(
                        title: 'No messages yet',
                        subtitle:
                            'Send the first message to start the conversation.',
                        icon: Icons.chat_bubble_outline,
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> msg =
                            messages[index].data();
                        final bool isMe =
                            (msg['senderId'] as String? ?? '') ==
                                firestore.currentUserId;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.only(
                              top: 4,
                              bottom: 4,
                              left: isMe ? 64 : 12,
                              right: isMe ? 12 : 64,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                            ),
                            child: Text(
                              msg['text'] as String? ?? '',
                              style: TextStyle(
                                color: isMe
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _messageCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Message $otherName…',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: () async {
                          final String text = _messageCtrl.text.trim();
                          if (text.isEmpty) return;
                          try {
                            await firestore.sendMessage(
                                chatId: widget.chatId, text: text);
                            _messageCtrl.clear();
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(firebaseErrorMessage(error))),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
