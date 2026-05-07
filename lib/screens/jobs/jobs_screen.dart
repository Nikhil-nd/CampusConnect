import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/auth_error_message.dart';
import '../../models/job_model.dart';
import '../../providers/feed_provider.dart';
import '../../routes/app_router.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/empty_state.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  static Uri? _normalizeUrlToUri(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    Uri? uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      uri = Uri.tryParse('https://$trimmed');
    }

    if (uri == null) {
      return null;
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }

    return uri.host.isEmpty ? null : uri;
  }

  static Future<void> _handleApply(BuildContext context, JobModel job) async {
    if (job.isFreelance) {
      if (job.contactInfo.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contact info provided for this freelance role.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contact: ${job.contactInfo}')),
      );
      return;
    }

    final Uri? uri = _normalizeUrlToUri(job.applyUrl);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or missing application URL for this job.')),
        );
      }
      return;
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open application URL.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestore = context.read<FirestoreService>();
    final FeedProvider feed = context.watch<FeedProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'jobs_fab',
        onPressed: () => _showCreateJobSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Post Job'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            AppSearchField(
              hintText: 'Search tutoring, freelance, editing...',
              onChanged: context.read<FeedProvider>().setSearchQuery,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<JobModel>>(
                stream: firestore.watchJobs(search: feed.searchQuery),
                builder: (BuildContext context, AsyncSnapshot<List<JobModel>> snapshot) {
                  if (snapshot.hasError) {
                    return EmptyState(
                      title: 'Could not load jobs',
                      subtitle: firebaseErrorMessage(snapshot.error!),
                      icon: Icons.wifi_off_outlined,
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<JobModel> jobs = snapshot.data!;
                  if (jobs.isEmpty) {
                    return const EmptyState(title: 'No jobs posted yet.');
                  }

                  return ListView.separated(
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final JobModel job = jobs[index];
                      final bool isOwnJob = job.postedBy == firestore.currentUserId;
                      return Card(
                        child: ListTile(
                          title: Text(job.title),
                          subtitle: Text(
                            '${job.desc}\nPay: ${job.pay}\n'
                            '${job.isFreelance ? 'Contact: ${job.contactInfo}' : 'Apply URL: ${job.applyUrl}'}',
                          ),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 4,
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(Icons.open_in_new),
                                tooltip: 'Apply',
                                onPressed: () => _handleApply(context, job),
                              ),
                              IconButton(
                                icon: const Icon(Icons.flag_outlined),
                                tooltip: 'Report spam',
                                onPressed: () async {
                                  await firestore.reportSpam(
                                    entityType: 'jobs',
                                    entityId: job.id,
                                    reason: 'Suspected spam',
                                    entityTitle: job.title,
                                  );
                                },
                              ),
                              if (!isOwnJob)
                                IconButton(
                                  icon: const Icon(Icons.chat_outlined),
                                  tooltip: 'Chat with poster',
                                  onPressed: () => _chatWithPoster(context, firestore, job),
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

  /// Opens (or creates) a DM thread with the job poster.
  static Future<void> _chatWithPoster(
    BuildContext context,
    FirestoreService firestore,
    JobModel job,
  ) async {
    if (job.postedBy.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poster info is not available for this job.')),
      );
      return;
    }

    try {
      final String chatId = await firestore.createOrGetChat(job.postedBy);
      if (!context.mounted) return;
      Navigator.pushNamed(context, AppRouter.chat, arguments: chatId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(firebaseErrorMessage(error))),
      );
    }
  }

  Future<void> _showCreateJobSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return _CreateJobSheet(parentContext: context);
      },
    );
  }
}

class _CreateJobSheet extends StatefulWidget {
  const _CreateJobSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_CreateJobSheet> createState() => _CreateJobSheetState();
}

class _CreateJobSheetState extends State<_CreateJobSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _payCtrl = TextEditingController();
  final TextEditingController _applyUrlCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();

  bool _isFreelance = false;
  String? _errorMessage;
  bool _posting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _payCtrl.dispose();
    _applyUrlCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Please fix the highlighted fields.';
      });
      return;
    }

    final FirestoreService firestore = widget.parentContext.read<FirestoreService>();

    setState(() {
      _posting = true;
      _errorMessage = null;
    });

    try {
      final JobModel job = JobModel(
        id: '',
        title: _titleCtrl.text.trim(),
        desc: _descCtrl.text.trim(),
        pay: _payCtrl.text.trim(),
        isFreelance: _isFreelance,
        applyUrl: _applyUrlCtrl.text.trim(),
        contactInfo: _contactCtrl.text.trim(),
        postedBy: firestore.currentUserId,
        createdAt: DateTime.now(),
      );
      await firestore.createJob(job);
      if (!mounted || !widget.parentContext.mounted) {
        return;
      }
      Navigator.pop(widget.parentContext);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not post job. Please try again.';
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
                decoration: const InputDecoration(labelText: 'Job Title'),
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
                controller: _payCtrl,
                decoration: const InputDecoration(labelText: 'Pay / Stipend'),
                validator: (String? value) => value == null || value.trim().isEmpty ? 'Pay required' : null,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _isFreelance,
                onChanged: (bool? value) {
                  setState(() {
                    _isFreelance = value ?? false;
                  });
                },
                title: const Text('This is a Freelance Role'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _applyUrlCtrl,
                decoration: InputDecoration(labelText: _isFreelance ? 'Contact Link (optional)' : 'Apply URL'),
                validator: (String? value) {
                  if (_isFreelance) return null;
                  return value == null || value.trim().isEmpty ? 'Apply URL required' : null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactCtrl,
                decoration: InputDecoration(labelText: _isFreelance ? 'Contact Info (Phone/Email)' : 'Poster Contact'),
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
                child: Text(_posting ? 'Posting...' : 'Post Job'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
