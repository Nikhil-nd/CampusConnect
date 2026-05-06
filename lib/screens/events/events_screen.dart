import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/auth_error_message.dart';
import '../../models/event_model.dart';
import '../../providers/feed_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/empty_state.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestore = context.read<FirestoreService>();
    final FeedProvider feed = context.watch<FeedProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'events_fab',
        onPressed: () => _showCreateEventSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Post Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            AppSearchField(
              hintText: 'Search workshops, hackathons, clubs...',
              onChanged: context.read<FeedProvider>().setSearchQuery,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<EventModel>>(
                stream: firestore.watchEvents(search: feed.searchQuery, includeMyPending: true),
                builder: (BuildContext context, AsyncSnapshot<List<EventModel>> snapshot) {
                  if (snapshot.hasError) {
                    return EmptyState(
                      title: 'Could not load events',
                      subtitle: firebaseErrorMessage(snapshot.error!),
                      icon: Icons.wifi_off_outlined,
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final List<EventModel> events = snapshot.data!;
                  if (events.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const EmptyState(
                          title: 'No events yet',
                          subtitle:
                              'Events are stored in Firestore (not temporary).\n\nOnly approved events show for everyone. Your pending events show only when you sign in with the same account, and past events are hidden.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _showCreateEventSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Post Event'),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final EventModel event = events[index];
                      final String statusLabel = event.approved ? 'Approved' : 'Pending Approval';
                      final String detailLine = event.isHackathon
                          ? 'Hackathon | Apply: ${event.applyUrl}'
                          : 'Tech Event | Contact: ${event.contactInfo}';
                      return Card(
                        child: ListTile(
                          title: Row(
                            children: <Widget>[
                              Expanded(child: Text(event.title)),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(statusLabel),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${DateFormat('dd MMM, hh:mm a').format(event.date)}\n${event.location.isEmpty ? 'Location to be shared' : event.location}\n$detailLine',
                          ),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 4,
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(Icons.flag_outlined),
                                onPressed: () async {
                                  await firestore.reportSpam(
                                    entityType: 'events',
                                    entityId: event.id,
                                    reason: 'Spam or irrelevant event',
                                    entityTitle: event.title,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.notifications_active_outlined),
                                onPressed: () async {
                                  final NotificationService notificationService = context.read<NotificationService>();
                                  await notificationService.scheduleEventReminder(
                                    id: event.id.hashCode,
                                    title: 'Event reminder',
                                    body: '${event.title} starts at ${DateFormat('dd MMM, hh:mm a').format(event.date)}',
                                    scheduledDate: event.date,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Reminder scheduled for ${event.title}')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateEventSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return _CreateEventSheet(parentContext: context);
      },
    );
  }
}

class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  final TextEditingController _applyUrlCtrl = TextEditingController();

  bool _isHackathon = false;
  DateTime _eventDateTime = DateTime.now().add(const Duration(hours: 1));
  String? _errorMessage;
  bool _posting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    _applyUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Please fix the highlighted fields.';
      });
      return;
    }

    if (_eventDateTime.isBefore(DateTime.now())) {
      setState(() {
        _errorMessage = 'Past events cannot be posted.';
      });
      return;
    }

    final FirestoreService firestore = widget.parentContext.read<FirestoreService>();

    setState(() {
      _posting = true;
      _errorMessage = null;
    });

    try {
      final EventModel event = EventModel(
        id: '',
        title: _titleCtrl.text.trim(),
        desc: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        date: _eventDateTime,
        isHackathon: _isHackathon,
        applyUrl: _applyUrlCtrl.text.trim(),
        contactInfo: _contactCtrl.text.trim(),
        organizer: '',
        organizerId: firestore.currentUserId,
        approved: false,
        registeredUsers: <String>[],
      );
      await firestore.createEvent(event);
      if (!mounted || !widget.parentContext.mounted) {
        return;
      }
      Navigator.pop(widget.parentContext);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not post event. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _posting = false;
        });
      }
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
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator: (String? value) => value == null || value.trim().isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (String? value) => value == null || value.trim().isEmpty ? 'Description required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (String? value) => value == null || value.trim().isEmpty ? 'Location required' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('Date & time: ${DateFormat('dd MMM yyyy, hh:mm a').format(_eventDateTime)}'),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _eventDateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        final TimeOfDay initialTime = TimeOfDay.fromDateTime(_eventDateTime);
                        if (!context.mounted) {
                          return;
                        }
                        final TimeOfDay? timePicked = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                        );
                        if (timePicked != null) {
                          setState(() {
                            _eventDateTime = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              timePicked.hour,
                              timePicked.minute,
                            );
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _isHackathon,
                onChanged: (bool? value) {
                  setState(() {
                    _isHackathon = value ?? false;
                  });
                },
                title: const Text('This is a Hackathon'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _applyUrlCtrl,
                decoration: const InputDecoration(labelText: 'Apply/Registration URL'),
                validator: (String? value) => value == null || value.trim().isEmpty ? 'URL required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactCtrl,
                decoration: const InputDecoration(labelText: 'Organizer Contact'),
                validator: (String? value) => value == null || value.trim().isEmpty ? 'Contact required' : null,
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
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _posting ? null : _submit,
                child: Text(_posting ? 'Posting...' : 'Post Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
