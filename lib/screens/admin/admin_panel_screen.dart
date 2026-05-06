import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/auth_error_message.dart';
import 'insights_screen.dart';
import '../../models/event_model.dart';
import '../../models/report_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController _collectionCtrl = TextEditingController(text: 'marketplace');
  final TextEditingController _docIdCtrl = TextEditingController();
  final TextEditingController _eventIdCtrl = TextEditingController();
  final TextEditingController _userIdCtrl = TextEditingController();
  final Map<String, bool> _approvingEventIds = <String, bool>{};

  @override
  void dispose() {
    _collectionCtrl.dispose();
    _docIdCtrl.dispose();
    _eventIdCtrl.dispose();
    _userIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Moderation Panel'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Moderation Dashboard',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text('Review pending approvals, inspect spam reports, and act quickly from one screen.'),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryCard(
                  icon: Icons.rule,
                  title: 'Event approvals',
                  subtitle: 'Pending review',
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.flag_outlined,
                  title: 'Spam reports',
                  subtitle: 'Unresolved queue',
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const InsightsScreen()));
              },
              icon: const Icon(Icons.insights_outlined),
              label: const Text('Insights'),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Pending Event Approvals', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          StreamBuilder<List<EventModel>>(
            stream: firestore.watchPendingEvents(),
            builder: (BuildContext context, AsyncSnapshot<List<EventModel>> snapshot) {
              if (snapshot.hasError) {
                return EmptyState(
                  title: 'Could not load pending events',
                  subtitle: firebaseErrorMessage(snapshot.error!),
                  icon: Icons.wifi_off_outlined,
                  actionLabel: 'Retry',
                  onAction: () => setState(() {}),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final List<EventModel> pending = snapshot.data!;
              if (pending.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No pending events.'),
                );
              }

              return Column(
                children: pending.map((EventModel event) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('ID: ${event.id}'),
                          Text('Organizer: ${event.organizer}'),
                          Text('When: ${DateFormat('dd MMM yyyy, hh:mm a').format(event.date)}'),
                          if (event.location.isNotEmpty) Text('Location: ${event.location}'),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              FilledButton(
                                onPressed: (_approvingEventIds[event.id] ?? false)
                                    ? null
                                    : () async {
                                        setState(() => _approvingEventIds[event.id] = true);
                                        try {
                                          await firestore.approveEvent(event.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Approved: ${event.title}')),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Could not approve event: $e')),
                                            );
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() => _approvingEventIds[event.id] = false);
                                          }
                                        }
                                      },
                                child: (_approvingEventIds[event.id] ?? false)
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Approve'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: (_approvingEventIds[event.id] ?? false)
                                    ? null
                                    : () async {
                                        setState(() => _approvingEventIds[event.id] = true);
                                        try {
                                          await firestore.rejectEvent(event.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Rejected: ${event.title}')),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Could not reject event: $e')),
                                            );
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() => _approvingEventIds[event.id] = false);
                                          }
                                        }
                                      },
                                child: (_approvingEventIds[event.id] ?? false)
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Reject'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          const Text('Spam Reports Queue', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          StreamBuilder<List<ReportModel>>(
            stream: firestore.watchReports(),
            builder: (BuildContext context, AsyncSnapshot<List<ReportModel>> snapshot) {
              if (snapshot.hasError) {
                return EmptyState(
                  title: 'Could not load reports',
                  subtitle: firebaseErrorMessage(snapshot.error!),
                  icon: Icons.wifi_off_outlined,
                  actionLabel: 'Retry',
                  onAction: () => setState(() {}),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final List<ReportModel> reports = snapshot.data!;
              if (reports.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No unresolved reports.'),
                );
              }

              return Column(
                children: reports.map((ReportModel report) {
                  final bool canDelete = report.entityType == 'marketplace' || report.entityType == 'jobs';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  report.entityTitle.isEmpty ? 'Reported ${report.entityType}' : report.entityTitle,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Chip(
                                label: Text(report.entityType),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Reason: ${report.reason}'),
                          Text('Item ID: ${report.entityId}'),
                          Text('Reported by: ${report.reportedBy.isEmpty ? 'Unknown' : report.reportedBy}'),
                          Text('At: ${DateFormat('dd MMM yyyy, hh:mm a').format(report.createdAt)}'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              FilledButton.tonalIcon(
                                onPressed: () async {
                                  try {
                                    await firestore.resolveReport(report.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Resolved report for ${report.entityTitle.isEmpty ? report.entityId : report.entityTitle}')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Could not resolve report: $e')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Resolve'),
                              ),
                              if (canDelete)
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await firestore.deleteSpamPost(report.entityType, report.entityId);
                                      await firestore.resolveReport(report.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Deleted ${report.entityType} item and resolved report.')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Could not delete item: $e')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete Item'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          const Text('Delete Spam Post'),
          TextField(controller: _collectionCtrl, decoration: const InputDecoration(labelText: 'Collection name')),
          TextField(controller: _docIdCtrl, decoration: const InputDecoration(labelText: 'Document ID')),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              try {
                await firestore.deleteSpamPost(_collectionCtrl.text.trim(), _docIdCtrl.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted.')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not delete post: $e')),
                  );
                }
              }
            },
            child: const Text('Delete Post'),
          ),
          const SizedBox(height: 20),
          const Text('Approve Event (Manual Fallback)'),
          TextField(controller: _eventIdCtrl, decoration: const InputDecoration(labelText: 'Event ID')),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              try {
                await firestore.approveEvent(_eventIdCtrl.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event approved.')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not approve event: $e')),
                  );
                }
              }
            },
            child: const Text('Approve Event'),
          ),
          const SizedBox(height: 20),
          const Text('Ban Fake User'),
          TextField(controller: _userIdCtrl, decoration: const InputDecoration(labelText: 'User ID')),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              try {
                await firestore.banUser(_userIdCtrl.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User banned.')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not ban user: $e')),
                  );
                }
              }
            },
            child: const Text('Ban User'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
