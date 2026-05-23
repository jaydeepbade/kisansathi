import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/marketplace_providers.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to dashboard event to automatically trigger upload form sheet
    marketplaceShowFormEvent.addListener(_handleShowFormEvent);
  }

  @override
  void dispose() {
    marketplaceShowFormEvent.removeListener(_handleShowFormEvent);
    super.dispose();
  }

  void _handleShowFormEvent() {
    if (marketplaceShowFormEvent.value == true) {
      marketplaceShowFormEvent.value = false; // Reset event
      // Wait for build to complete before opening bottom sheet
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showListingFormSheet(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsState = ref.watch(marketplaceListingsProvider);
    final activeFilter = ref.watch(cropFilterProvider);
    final cartCount = ref.watch(cartCountProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.getTranslate('market_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Shopping cart with glowing count badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cart feature coming soon! ($cartCount items selected)'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar & Add Button Row
          _buildSearchAndAddBar(isDark, loc),

          // 2. Horizontal Filter Chips Panel
          _buildFilterChipsRow(activeFilter, loc),

          // 3. GridView of Produce Listings
          Expanded(
            child: listingsState.when(
              data: (listings) {
                // Apply category filtering
                final filteredList = listings.where((listing) {
                  if (activeFilter == 'All') return true;
                  return listing.category.toLowerCase() == activeFilter.toLowerCase();
                }).toList();

                if (filteredList.isEmpty) {
                  return _buildEmptyState(loc);
                }

                return _buildProduceGrid(filteredList, isDark, loc);
              },
              loading: () => _buildShimmerGrid(),
              error: (err, _) => _buildErrorState(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showListingFormSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSearchAndAddBar(bool isDark, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: loc.getTranslate('search_placeholder'),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: const Icon(Icons.tune, color: AppColors.primary),
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChipsRow(String activeFilter, AppLocalizations loc) {
    final categories = ['All', 'Grains', 'Vegetables', 'Fruits'];
    final labels = [
      loc.getTranslate('filter_all'),
      loc.getTranslate('filter_grains'),
      loc.getTranslate('filter_vegetables'),
      loc.getTranslate('filter_fruits')
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(categories.length, (index) {
          final cat = categories[index];
          final label = labels[index];
          final isSelected = activeFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(cropFilterProvider.notifier).setFilter(cat);
                }
              },
              selectedColor: AppColors.primary.withAlpha(51),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProduceGrid(List<CropListing> listings, bool isDark, AppLocalizations loc) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: listings.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final crop = listings[index];
        return _buildCropCard(crop, isDark, loc);
      },
    );
  }

  Widget _buildCropCard(CropListing crop, bool isDark, AppLocalizations loc) {
    // Generate beautiful custom color vectors based on crop categories instead of placeholders
    Color cropColor = AppColors.primary;
    IconData cropIcon = Icons.eco;
    if (crop.category == 'Vegetables') {
      cropColor = Colors.orange;
      cropIcon = Icons.restaurant;
    } else if (crop.category == 'Fruits') {
      cropColor = Colors.red;
      cropIcon = Icons.shopping_basket;
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop stylized image header
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cropColor.withAlpha(38),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(cropIcon, color: cropColor, size: 52),
                  // Freshness badge overlay
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        crop.freshness,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Info descriptions
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.cropName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Qty: ${crop.quantity} kg',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '📍 ${crop.distanceKm} km',
                            style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${crop.pricePerKg}/kg',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  // Actions buttons row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showChatDialog(crop.cropName),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size.fromHeight(32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            loc.getTranslate('chat_farmer'),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(cartCountProvider.notifier).increment();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.getTranslate('added_to_cart')),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size.fromHeight(32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            loc.getTranslate('add_to_cart'),
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatDialog(String cropName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.forum, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Farmer Secure Chat'),
          ],
        ),
        content: Text(
          'Connecting secure chat channel to the farmer of "$cropName". Realtime negotiations and secure UPI payments are encrypted. (चैनल से जोड़ा जा रहा है...)',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Connect Chat'),
          ),
        ],
      ),
    );
  }

  void _showListingFormSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String cropName = 'Tomato (टमाटर)';
    String category = 'Vegetables';
    double qty = 100.0;
    double price = 40.0;
    String location = 'Pune, Maharashtra';
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Publish New Produce Listing',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image Pick Mock UI
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withAlpha(76), style: BorderStyle.values[1]),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo, color: AppColors.primary, size: 36),
                            SizedBox(height: 8),
                            Text(
                              'Camera / Crop Photo Upload',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Crop Category Selection Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'Crop Category'),
                        items: ['Grains', 'Vegetables', 'Fruits'].map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() {
                              category = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Crop Name input
                      TextFormField(
                        initialValue: cropName,
                        decoration: const InputDecoration(labelText: 'Crop Name (e.g. Basmati Rice)'),
                        validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                        onSaved: (val) => cropName = val ?? '',
                      ),
                      const SizedBox(height: 12),

                      // Quantity and Price Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '$qty',
                              decoration: const InputDecoration(labelText: 'Quantity (kg)'),
                              keyboardType: TextInputType.number,
                              validator: (val) => double.tryParse(val ?? '') == null ? 'Must be a number' : null,
                              onSaved: (val) => qty = double.tryParse(val ?? '') ?? 100.0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: '$price',
                              decoration: const InputDecoration(labelText: 'Price / kg (₹)'),
                              keyboardType: TextInputType.number,
                              validator: (val) => double.tryParse(val ?? '') == null ? 'Must be a number' : null,
                              onSaved: (val) => price = double.tryParse(val ?? '') ?? 40.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Location Input
                      TextFormField(
                        initialValue: location,
                        decoration: const InputDecoration(labelText: 'Location / Market Mandi'),
                        validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                        onSaved: (val) => location = val ?? '',
                      ),
                      const SizedBox(height: 16),

                      // Harvest Date Picker UI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Harvest Date: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: const Text('Change Date'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Publish Button
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            
                            // Create CropListing object and append dynamically
                            final newCrop = CropListing(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              cropName: cropName,
                              category: category,
                              quantity: qty,
                              pricePerKg: price,
                              location: location,
                              distanceKm: 8,
                              freshness: 'Freshly Harvested',
                              imagePath: category.toLowerCase(),
                              harvestDate: selectedDate.toString().split(' ')[0],
                            );
                            
                            ref.read(marketplaceListingsProvider.notifier).addListing(newCrop);
                            
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('New Crop Listing published successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        child: const Text('Publish Listing'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No crop listings found in this category.'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.read(cropFilterProvider.notifier).setFilter('All');
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('Failed to load marketplace listings.'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ref.read(marketplaceListingsProvider.notifier).fetchListings();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
