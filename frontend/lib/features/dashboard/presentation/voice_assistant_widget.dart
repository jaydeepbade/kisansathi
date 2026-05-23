import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class VoiceAssistantWidget extends ConsumerStatefulWidget {
  const VoiceAssistantWidget({super.key});

  @override
  ConsumerState<VoiceAssistantWidget> createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends ConsumerState<VoiceAssistantWidget> with SingleTickerProviderStateMixin {
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    // Auto-speak when bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakGreeting();
    });
  }

  Future<void> _speakGreeting() async {
    final activeLocale = ref.read(localeProvider);
    final loc = AppLocalizations.of(context, ref);
    
    String languageCode = 'en-IN';
    if (activeLocale == AppLocale.hi) {
      languageCode = 'hi-IN';
    } else if (activeLocale == AppLocale.mr) {
      languageCode = 'mr-IN'; // Marathi might fallback to Hindi on some devices depending on TTS engine, but we set it
    }

    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    setState(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });

    await _flutterTts.speak(loc.getTranslate('how_can_i_help'));
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context, ref);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            loc.getTranslate('voice_assistant'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            loc.getTranslate('how_can_i_help'),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.all(_isSpeaking ? 16.0 + (_animationController.value * 8) : 16.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(_isSpeaking ? (50 + (_animationController.value * 50)).toInt() : 25),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: Icon(
                    _isSpeaking ? Icons.graphic_eq : Icons.mic,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            _isSpeaking ? loc.getTranslate('listening') : '...',
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
