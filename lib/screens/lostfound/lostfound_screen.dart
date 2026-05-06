import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/auth_error_message.dart';
import '../../models/lost_found_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';

class LostFoundScreen extends StatelessWidget {
  const LostFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lost & Found')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'lostfound_fab',
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Alert'),
      ),
      body: StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setLocalState) {
          return StreamBuilder<List<LostFoundModel>>(
            stream: firestore.watchLostFound(),
            builder: (BuildContext context, AsyncSnapshot<List<LostFoundModel>> snapshot) {
              if (snapshot.hasError) {
                return EmptyState(
                  title: 'Could not load lost and found',
                  subtitle: firebaseErrorMessage(snapshot.error!),
                  icon: Icons.wifi_off_outlined,
                  actionLabel: 'Retry',
                  onAction: () => setLocalState(() {}),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<LostFoundModel> items = snapshot.data!;
              if (items.isEmpty) {
                return const EmptyState(title: 'No lost/found posts yet.');
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final LostFoundModel item = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.itemName),
                      subtitle: Text('${item.type.toUpperCase()} - ${item.location}\nContact: ${item.contact}'),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context) async {
    final TextEditingController itemCtrl = TextEditingController();
    final TextEditingController locationCtrl = TextEditingController();
    final TextEditingController contactCtrl = TextEditingController();
    String type = 'lost';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(controller: itemCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(value: 'lost', child: Text('Lost')),
                      DropdownMenuItem<String>(value: 'found', child: Text('Found')),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => type = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
                  const SizedBox(height: 8),
                  TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact')), 
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      final FirestoreService firestore = context.read<FirestoreService>();
                      final LostFoundModel model = LostFoundModel(
                        id: '',
                        itemName: itemCtrl.text.trim(),
                        type: type,
                        location: locationCtrl.text.trim(),
                        contact: contactCtrl.text.trim(),
                        createdBy: firestore.currentUserId,
                        createdAt: DateTime.now(),
                      );
                      await firestore.createLostFound(model);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Post Alert'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
