import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/auth_error_message.dart';
import '../../models/event_model.dart';
import '../../providers/feed_provider.dart';
import '../../routes/app_router.dart';
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
                        const EmptyState(title: 'No events yet. Your submissions will appear as Pending.'),
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
                      final bool isOwnEvent = event.organizerId == firestore.currentUserId;
                      return _EventCard(
                        event: event,
                        isOwnEvent: isOwnEvent,
                        onChatPressed: () => _chatWithOrganizer(context, firestore, event),
                        onReminderPressed: () => _setReminder(context, event),
                        onReportPressed: () async {
                          await firestore.reportSpam(
                            entityType: 'events',
                            entityId: event.id,
                            reason: 'Spam or irrelevant event',
                            entityTitle: event.title,
                          );
                        },
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

  /// Schedules a reminder 1 hour before the event.
  static Future<void> _setReminder(BuildContext context, EventModel event) async {
    final DateTime reminderTime = event.date.subtract(const Duration(hours: 1));

    // On web, local notifications are not supported — show a helpful message.
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder set! Mark your calendar: ${event.title} on '
            '${DateFormat('dd MMM, hh:mm a').format(event.date)}.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // If the event or the 1-hour reminder window has already passed.
    if (reminderTime.isBefore(DateTime.now())) {
      if (event.date.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This event has already passed.')),
        );
      } else {
        // Less than 1 hour away — show immediate notification.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${event.title} is less than 1 hour away! Starting at '
              '${DateFormat('hh:mm a').format(event.date)}.',
            ),
          ),
        );
      }
      return;
    }

    final NotificationService notificationService = context.read<NotificationService>();
    try {
      await notificationService.scheduleEventReminder(
        id: event.id.hashCode,
        title: '🔔 Event Reminder',
        body: '${event.title} starts in 1 hour at ${DateFormat('hh:mm a').format(event.date)}',
        scheduledDate: reminderTime,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder set for 1 hour before ${event.title} '
              '(${DateFormat('dd MMM, hh:mm a').format(reminderTime)}).',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not set reminder. Please try again.')),
        );
      }
    }
  }

  /// Opens (or creates) a DM thread with the event organizer.
  static Future<void> _chatWithOrganizer(
    BuildContext context,
    FirestoreService firestore,
    EventModel event,
  ) async {
    if (event.organizerId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organizer contact is not available for this event.')),
      );
      return;
    }

    try {
      final String chatId = await firestore.createOrGetChat(event.organizerId);
      if (!context.mounted) return;
      Navigator.pushNamed(context, AppRouter.chat, arguments: chatId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(firebaseErrorMessage(error))),
      );
    }
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

// ---------------------------------------------------------------------------
// Event Card
// ---------------------------------------------------------------------------

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.isOwnEvent,
    required this.onChatPressed,
    required this.onReminderPressed,
    required this.onReportPressed,
  });

  final EventModel event;
  final bool isOwnEvent;
  final VoidCallback onChatPressed;
  final VoidCallback onReminderPressed;
  final VoidCallback onReportPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final bool isPast = event.date.isBefore(DateTime.now());
    final bool hasUrl = event.applyUrl.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Header row: title + status chip ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    event.title,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    event.approved ? 'Approved' : 'Pending',
                    style: tt.labelSmall,
                  ),
                  backgroundColor: event.approved
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Event type badge ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: event.isHackathon ? cs.tertiaryContainer : cs.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                event.isHackathon ? '🏆 Hackathon' : '🎓 Tech Event',
                style: tt.labelSmall?.copyWith(
                  color: event.isHackathon ? cs.onTertiaryContainer : cs.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Date & time ──
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text: DateFormat('EEE, dd MMM yyyy • hh:mm a').format(event.date),
              color: isPast ? cs.error : null,
            ),
            const SizedBox(height: 4),

            // ── Location ──
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: event.location.isEmpty ? 'Location to be shared' : event.location,
            ),
            const SizedBox(height: 4),

            // ── Contact info ──
            if (event.contactInfo.isNotEmpty) ...<Widget>[
              _InfoRow(
                icon: Icons.person_outline,
                text: event.contactInfo,
              ),
              const SizedBox(height: 4),
            ],

            const Divider(height: 20),

            // ── Action row ──
            Row(
              children: <Widget>[
                // Apply button
                if (hasUrl)
                  FilledButton.icon(
                    onPressed: () => _launchUrl(context, event.applyUrl),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Apply'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.link_off, size: 16),
                    label: const Text('No link'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),

                const Spacer(),

                // Reminder icon
                IconButton(
                  icon: const Icon(Icons.notifications_active_outlined),
                  tooltip: 'Set reminder (1 hr before)',
                  visualDensity: VisualDensity.compact,
                  onPressed: onReminderPressed,
                ),

                // Chat icon (only for other organizers)
                if (!isOwnEvent)
                  IconButton(
                    icon: const Icon(Icons.chat_outlined),
                    tooltip: 'Chat with organizer',
                    visualDensity: VisualDensity.compact,
                    onPressed: onChatPressed,
                  ),

                // Report icon
                IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  tooltip: 'Report spam',
                  visualDensity: VisualDensity.compact,
                  onPressed: onReportPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL for this event.')),
        );
      }
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link.')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Small helper widget for icon + text rows inside the card
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 15, color: effectiveColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: effectiveColor),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Create Event Bottom Sheet
// ---------------------------------------------------------------------------

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
  bool _noUrl = false; // organizer has no registration URL
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

  /// Validates that [value] is a well-formed http/https URL.
  String? _validateUrl(String? value) {
    if (_noUrl) return null; // skipped — organizer has no URL
    if (value == null || value.trim().isEmpty) {
      return 'Registration URL is required.';
    }
    final Uri? uri = Uri.tryParse(value.trim());
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return 'Enter a valid URL starting with http:// or https://';
    }
    if (uri.host.isEmpty) {
      return 'Enter a valid URL (e.g. https://devfolio.co/hackathon)';
    }
    return null;
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
        applyUrl: _noUrl ? '' : _applyUrlCtrl.text.trim(),
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
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Sheet drag handle & title
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Post an Event',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Event Title', prefixIcon: Icon(Icons.title)),
                textCapitalization: TextCapitalization.words,
                validator: (String? value) =>
                    value == null || value.trim().isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (String? value) =>
                    value == null || value.trim().isEmpty ? 'Description required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty ? 'Location required' : null,
              ),
              const SizedBox(height: 12),

              // Date & time picker
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _eventDateTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    final TimeOfDay initialTime = TimeOfDay.fromDateTime(_eventDateTime);
                    if (!context.mounted) return;
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
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date & Time',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.edit_outlined),
                  ),
                  child: Text(
                    DateFormat('EEE, dd MMM yyyy • hh:mm a').format(_eventDateTime),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Hackathon toggle
              CheckboxListTile(
                value: _isHackathon,
                onChanged: (bool? value) {
                  setState(() {
                    _isHackathon = value ?? false;
                  });
                },
                title: const Text('This is a Hackathon'),
                secondary: const Icon(Icons.code_outlined),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 4),

              // Registration URL field
              if (!_noUrl) ...<Widget>[
                TextFormField(
                  controller: _applyUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Registration / Apply URL',
                    hintText: 'https://example.com/register',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  validator: _validateUrl,
                ),
                const SizedBox(height: 4),
              ],

              // "No URL" toggle
              CheckboxListTile(
                value: _noUrl,
                onChanged: (bool? value) {
                  setState(() {
                    _noUrl = value ?? false;
                    if (_noUrl) {
                      _applyUrlCtrl.clear();
                    }
                  });
                },
                title: const Text("I don't have a registration link"),
                secondary: const Icon(Icons.link_off_outlined),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 4),

              TextFormField(
                controller: _contactCtrl,
                decoration: const InputDecoration(
                  labelText: 'Organizer Contact (email / phone / social)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty ? 'Contact info required' : null,
              ),
              const SizedBox(height: 16),

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

              FilledButton.icon(
                onPressed: _posting ? null : _submit,
                icon: _posting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_posting ? 'Posting…' : 'Post Event'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
