import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/auth_error_message.dart';
import '../../models/lost_found_model.dart';
import '../../routes/app_router.dart';
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
                return EmptyState(
                  title: 'No lost/found posts yet.',
                  subtitle: 'Post an alert if you lost or found something.',
                  icon: Icons.search_off_outlined,
                  actionLabel: 'Post Alert',
                  onAction: () => _showCreateSheet(context),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final LostFoundModel item = items[index];
                  final bool isOwn = item.createdBy == firestore.currentUserId;
                  final Color typeColor = item.type == 'lost'
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: typeColor.withValues(alpha: 0.12),
                        child: Icon(
                          item.type == 'lost'
                              ? Icons.help_outline
                              : Icons.check_circle_outline,
                          color: typeColor,
                        ),
                      ),
                      title: Row(
                        children: <Widget>[
                          Expanded(child: Text(item.itemName)),
                          const SizedBox(width: 6),
                          Chip(
                            label: Text(item.type.toUpperCase()),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: typeColor.withValues(alpha: 0.12),
                            labelStyle: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '📍 ${item.location.isEmpty ? 'Location not specified' : item.location}'
                        '${item.contact.isEmpty ? '' : '\n📞 ${item.contact}'}',
                      ),
                      isThreeLine: item.contact.isNotEmpty,
                      trailing: isOwn
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.chat_outlined),
                              tooltip: 'Chat with reporter',
                              onPressed: () =>
                                  _chatWithReporter(context, firestore, item),
                            ),
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

  /// Opens (or creates) a DM thread with the person who posted the alert.
  static Future<void> _chatWithReporter(
    BuildContext context,
    FirestoreService firestore,
    LostFoundModel item,
  ) async {
    if (item.createdBy.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Reporter info is not available for this alert.')),
      );
      return;
    }

    try {
      final String chatId = await firestore.createOrGetChat(item.createdBy);
      if (!context.mounted) return;
      Navigator.pushNamed(context, AppRouter.chat, arguments: chatId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(firebaseErrorMessage(error))),
      );
    }
  }

  Future<void> _showCreateSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return _CreateLostFoundSheet(parentContext: context);
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _CreateLostFoundSheet extends StatefulWidget {
  const _CreateLostFoundSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_CreateLostFoundSheet> createState() => _CreateLostFoundSheetState();
}

class _CreateLostFoundSheetState extends State<_CreateLostFoundSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _itemCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  String _type = 'lost';
  bool _posting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _itemCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final FirestoreService firestore =
        widget.parentContext.read<FirestoreService>();

    setState(() {
      _posting = true;
      _errorMessage = null;
    });

    try {
      final LostFoundModel model = LostFoundModel(
        id: '',
        itemName: _itemCtrl.text.trim(),
        type: _type,
        location: _locationCtrl.text.trim(),
        contact: _contactCtrl.text.trim(),
        createdBy: firestore.currentUserId,
        createdAt: DateTime.now(),
      );
      await firestore.createLostFound(model);
      if (!mounted || !widget.parentContext.mounted) return;
      Navigator.pop(widget.parentContext);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not post alert. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Post Lost / Found Alert',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _itemCtrl,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                        ? 'Item name is required'
                        : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'lost', child: Text('Lost')),
                  DropdownMenuItem<String>(
                      value: 'found', child: Text('Found')),
                ],
                onChanged: (String? value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                        ? 'Location is required'
                        : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact (optional)',
                  hintText: 'Phone, email, or social handle',
                ),
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null) ...<Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _posting ? null : _submit,
                child: Text(_posting ? 'Posting...' : 'Post Alert'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
