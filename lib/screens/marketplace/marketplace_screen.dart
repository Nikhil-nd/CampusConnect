import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/auth_error_message.dart';
import '../../models/marketplace_model.dart';
import '../../providers/feed_provider.dart';
import '../../routes/app_router.dart';
import '../../services/analytics_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/empty_state.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  static Future<void> _showBuyOptions(
    BuildContext context,
    MarketplaceModel item,
    FirestoreService firestore,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Price: INR ${item.price.toStringAsFixed(0)}'),
              Text('Location: ${item.location.isEmpty ? 'Not provided' : item.location}'),
              Text('Contact: ${item.contactInfo.isEmpty ? 'Not provided' : item.contactInfo}'),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: item.contactInfo.isEmpty
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Seller contact: ${item.contactInfo}')),
                        );
                      },
                icon: const Icon(Icons.call_outlined),
                label: const Text('Use Contact Info'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: item.sellerId.isEmpty
                    ? null
                    : () async {
                        final String chatId = await firestore.createOrGetChat(item.sellerId);
                        if (context.mounted) {
                          Navigator.pop(sheetContext);
                          Navigator.pushNamed(context, AppRouter.chat, arguments: chatId);
                        }
                      },
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Start Chat'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestore = context.read<FirestoreService>();
    final FeedProvider feed = context.watch<FeedProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'marketplace_fab',
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Post Listing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            AppSearchField(
              hintText: 'Search products, services, books...',
              onChanged: context.read<FeedProvider>().setSearchQuery,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: context.read<FeedProvider>().togglePriceSort,
                    icon: Icon(feed.priceLowToHigh ? Icons.arrow_upward : Icons.arrow_downward),
                    label: Text(feed.priceLowToHigh ? 'Price: Low to High' : 'Price: High to Low'),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _showCreateSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Post'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<MarketplaceModel>>(
                stream: firestore.watchMarketplace(
                  search: feed.searchQuery,
                  lowToHigh: feed.priceLowToHigh,
                ),
                builder: (BuildContext context, AsyncSnapshot<List<MarketplaceModel>> snapshot) {
                  if (snapshot.hasError) {
                    return EmptyState(
                      title: 'Could not load marketplace',
                      subtitle: firebaseErrorMessage(snapshot.error!),
                      icon: Icons.wifi_off_outlined,
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<MarketplaceModel> items = snapshot.data!;
                  if (items.isEmpty) {
                    return const EmptyState(title: 'No listings yet. Add your first one.');
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final MarketplaceModel item = items[index];
                      final bool isOwner = item.sellerId == firestore.currentUserId;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: <Widget>[
                              ListTile(
                                leading: item.image.isEmpty
                                    ? const CircleAvatar(child: Icon(Icons.image_outlined))
                                    : ClipOval(
                                        child: SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: CachedNetworkImage(
                                            imageUrl: item.image,
                                            fit: BoxFit.cover,
                                            placeholder: (BuildContext context, String url) => const ColoredBox(
                                              color: Color(0xFFECEFF1),
                                              child: Icon(Icons.image_outlined),
                                            ),
                                            errorWidget: (BuildContext context, String url, dynamic error) =>
                                                const ColoredBox(
                                                  color: Color(0xFFECEFF1),
                                                  child: Icon(Icons.broken_image_outlined),
                                                ),
                                          ),
                                        ),
                                      ),
                                title: Text(item.title),
                                subtitle: Text(
                                  '${item.category} - INR ${item.price.toStringAsFixed(0)}\n'
                                  'Location: ${item.location.isEmpty ? 'Not provided' : item.location}\n'
                                  'Contact: ${item.contactInfo.isEmpty ? 'Not provided' : item.contactInfo}',
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (String value) async {
                                    if (value == 'sold') {
                                      await firestore.markMarketplaceSold(item.id);
                                    }
                                    if (value == 'report') {
                                      await firestore.reportSpam(
                                        entityType: 'marketplace',
                                        entityId: item.id,
                                        reason: 'Spam or suspicious listing',
                                        entityTitle: item.title,
                                      );
                                    }
                                  },
                                  itemBuilder: (_) {
                                    final List<PopupMenuEntry<String>> entries = <PopupMenuEntry<String>>[];
                                    if (isOwner) {
                                      entries.add(
                                        const PopupMenuItem<String>(
                                          value: 'sold',
                                          child: Text('Mark Sold'),
                                        ),
                                      );
                                    }
                                    entries.add(
                                      const PopupMenuItem<String>(
                                        value: 'report',
                                        child: Text('Report Spam'),
                                      ),
                                    );
                                    return entries;
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text('Status: ${item.status}'),
                                    TextButton.icon(
                                      onPressed: () => _showBuyOptions(context, item, firestore),
                                      icon: const Icon(Icons.shopping_cart_outlined),
                                      label: const Text('Contact Seller'),
                                    ),
                                  ],
                                ),
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

  Future<void> _showCreateSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return _CreateMarketplaceListingSheet(parentContext: context);
      },
    );
  }
}

class _CreateMarketplaceListingSheet extends StatefulWidget {
  const _CreateMarketplaceListingSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_CreateMarketplaceListingSheet> createState() => _CreateMarketplaceListingSheetState();
}

class _CreateMarketplaceListingSheetState extends State<_CreateMarketplaceListingSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();

  String _category = AppConstants.marketplaceCategories.first;
  String? _errorMessage;
  bool _posting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
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

    final String title = _titleCtrl.text.trim();
    final String description = _descCtrl.text.trim();
    final String location = _locationCtrl.text.trim();
    final String contact = _contactCtrl.text.trim();
    final double? parsedPrice = double.tryParse(_priceCtrl.text.trim());

    if (title.isEmpty || description.isEmpty || location.isEmpty || contact.isEmpty) {
      setState(() {
        _errorMessage = 'Title, description, location, and contact are required.';
      });
      return;
    }

    if (parsedPrice == null || parsedPrice <= 0) {
      setState(() {
        _errorMessage = 'Enter a valid price greater than 0.';
      });
      return;
    }

    final FirestoreService firestore = widget.parentContext.read<FirestoreService>();
    final AnalyticsService analytics = AnalyticsService();

    setState(() {
      _posting = true;
      _errorMessage = null;
    });

    try {
      final MarketplaceModel model = MarketplaceModel(
        id: '',
        title: title,
        price: parsedPrice,
        image: '',
        sellerId: firestore.currentUserId,
        category: _category,
        description: description,
        location: location,
        contactInfo: contact,
        status: 'available',
        createdAt: DateTime.now(),
      );

      await firestore.createMarketplacePost(model);
      await analytics.logCreatePost('marketplace');

      if (!mounted || !widget.parentContext.mounted) {
        return;
      }
      Navigator.pop(widget.parentContext);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not post listing right now. Please try again.';
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
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (String? value) => value == null || value.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (String? value) => value == null || value.trim().isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (String? value) {
                  final double? parsedPrice = double.tryParse((value ?? '').trim());
                  if (parsedPrice == null || parsedPrice <= 0) {
                    return 'Enter a price greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (String? value) => value == null || value.trim().isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Info',
                  hintText: 'Phone, email, or social handle',
                ),
                validator: (String? value) => value == null || value.trim().isEmpty ? 'Contact info is required' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: AppConstants.marketplaceCategories
                    .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                    .toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
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
                child: Text(_posting ? 'Posting...' : 'Post Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
