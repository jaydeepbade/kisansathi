import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class RecommendationItem {
  final String id;
  final String category; // 'weather', 'price', 'disease'
  final String titleEN;
  final String titleHI;
  final String messageEN;
  final String messageHI;
  final IconData icon;
  final Color cardColor;
  bool? isUpvoted; // null, true, false

  RecommendationItem({
    required this.id,
    required this.category,
    required this.titleEN,
    required this.titleHI,
    required this.messageEN,
    required this.messageHI,
    required this.icon,
    required this.cardColor,
    this.isUpvoted,
  });
}

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  final List<RecommendationItem> _suggestions = [
    RecommendationItem(
      id: '1',
      category: 'weather',
      titleEN: 'Optimal Sowing Advisory',
      titleHI: 'सर्वोत्तम बुवाई सलाह',
      messageEN: 'Rain expected Thursday — ideal environment for sowing wheat crop seeds in clay soil.',
      messageHI: 'गुरुवार को बारिश की उम्मीद है - मिट्टी में गेहूं की फसल के बीज बोने के लिए आदर्श वातावरण।',
      icon: Icons.thunderstorm,
      cardColor: Colors.blue.shade600,
    ),
    RecommendationItem(
      id: '2',
      category: 'price',
      titleEN: 'Market Mandi Trend Warning',
      titleHI: 'बाजार मंडी मूल्य चेतावनी',
      messageEN: 'Tomato prices are up 23% in Pune mandi — highly recommended to publish active listings today.',
      messageHI: 'पुणे मंडी में टमाटर की कीमतें 23% बढ़ गई हैं - आज ही अपनी उपज सूचीबद्ध करने की सलाह दी जाती है।',
      icon: Icons.trending_up,
      cardColor: AppColors.secondary,
    ),
    RecommendationItem(
      id: '3',
      category: 'disease',
      titleEN: 'Disease Blight Warning',
      titleHI: 'झुलसा रोग की चेतावनी',
      messageEN: 'High humidity forecast this week — watch for early signs of late blight infection on potatoes.',
      messageHI: 'इस सप्ताह उच्च आर्द्रता का पूर्वानुमान है - आलू पर पछेती झुलसा संक्रमण के शुरुआती लक्षणों पर नज़र रखें।',
      icon: Icons.bug_report,
      cardColor: AppColors.error,
    ),
  ];

  void _handleVote(int index, bool upvote, AppLocalizations loc) {
    setState(() {
      final current = _suggestions[index].isUpvoted;
      if (current == upvote) {
        // Untoggle vote
        _suggestions[index].isUpvoted = null;
      } else {
        _suggestions[index].isUpvoted = upvote;
        // Show success/feedback toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              upvote
                  ? loc.getTranslate('thumbs_up_toast')
                  : loc.getTranslate('thumbs_down_toast'),
            ),
            backgroundColor: upvote ? AppColors.success : Colors.grey.shade800,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeLocale = ref.watch(localeProvider);
    final loc = AppLocalizations.of(context, ref);
    final isHindi = activeLocale == AppLocale.hi || activeLocale == AppLocale.mr;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Advisory Feed (एआई कृषि सलाह)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          final String title = isHindi ? item.titleHI : item.titleEN;
          final String desc = isHindi ? item.messageHI : item.messageEN;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Category label
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.cardColor.withAlpha(38),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: item.cardColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: item.cardColor,
                          ),
                        ),
                      ),
                      // AI badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'AI AGRI',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Message Body
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Voting row controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Was this suggestion helpful?',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      Row(
                        children: [
                          // Thumbs Up
                          IconButton(
                            icon: Icon(
                              item.isUpvoted == true ? Icons.thumb_up : Icons.thumb_up_outlined,
                              color: item.isUpvoted == true ? AppColors.primary : Colors.grey,
                              size: 20,
                            ),
                            onPressed: () => _handleVote(index, true, loc),
                          ),
                          const SizedBox(width: 8),
                          // Thumbs Down
                          IconButton(
                            icon: Icon(
                              item.isUpvoted == false ? Icons.thumb_down : Icons.thumb_down_outlined,
                              color: item.isUpvoted == false ? AppColors.error : Colors.grey,
                              size: 20,
                            ),
                            onPressed: () => _handleVote(index, false, loc),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
