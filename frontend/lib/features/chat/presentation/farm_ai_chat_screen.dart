import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/api/openai_service.dart';
import '../../../core/api/weather_service.dart';
import '../../../core/api/market_service.dart';
import '../../../core/theme/app_colors.dart';

// ─── Message Model ────────────────────────────────────────────────────────────
enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({String? content, bool? isLoading}) => ChatMessage(
        id: id,
        role: role,
        content: content ?? this.content,
        timestamp: timestamp,
        isLoading: isLoading ?? this.isLoading,
      );

  Map<String, String> toOpenAIMap() => {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': content,
      };
}

// ─── Language Enum ────────────────────────────────────────────────────────────
enum ChatLanguage { english, hindi, marathi }

extension ChatLanguageX on ChatLanguage {
  String get label => switch (this) {
        ChatLanguage.english => 'English',
        ChatLanguage.hindi => 'हिंदी',
        ChatLanguage.marathi => 'मराठी',
      };
  String get code => switch (this) {
        ChatLanguage.english => 'English',
        ChatLanguage.hindi => 'Hindi',
        ChatLanguage.marathi => 'Marathi',
      };
  String get ttsLocale => switch (this) {
        ChatLanguage.english => 'en-IN',
        ChatLanguage.hindi => 'hi-IN',
        ChatLanguage.marathi => 'mr-IN',
      };
  String get sttLocale => switch (this) {
        ChatLanguage.english => 'en_IN',
        ChatLanguage.hindi => 'hi_IN',
        ChatLanguage.marathi => 'mr_IN',
      };
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final chatScreenProvider =
    StateNotifierProvider.autoDispose<ChatScreenNotifier, ChatScreenState>(
        (ref) => ChatScreenNotifier(
              openAI: ref.read(openAIServiceProvider),
              weather: ref.read(weatherServiceProvider),
              market: ref.read(marketServiceProvider),
            ));

// ─── State ────────────────────────────────────────────────────────────────────
class ChatScreenState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final ChatLanguage language;
  final bool isListening;
  final WeatherData? weatherData;
  final String? marketContext;

  const ChatScreenState({
    this.messages = const [],
    this.isTyping = false,
    this.language = ChatLanguage.english,
    this.isListening = false,
    this.weatherData,
    this.marketContext,
  });

  ChatScreenState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    ChatLanguage? language,
    bool? isListening,
    WeatherData? weatherData,
    String? marketContext,
  }) =>
      ChatScreenState(
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
        language: language ?? this.language,
        isListening: isListening ?? this.isListening,
        weatherData: weatherData ?? this.weatherData,
        marketContext: marketContext ?? this.marketContext,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class ChatScreenNotifier extends StateNotifier<ChatScreenState> {
  final OpenAIService openAI;
  final WeatherService weather;
  final MarketService market;

  ChatScreenNotifier({
    required this.openAI,
    required this.weather,
    required this.market,
  }) : super(const ChatScreenState()) {
    _init();
  }

  Future<void> _init() async {
    // Load context data in background
    final results = await Future.wait([
      weather.fetchWeather('Pune'),
      market.getMarketContextString('Maharashtra'),
    ]);
    if (mounted) {
      state = state.copyWith(
        weatherData: results[0] as WeatherData?,
        marketContext: results[1] as String?,
      );
    }

    // Send welcome message
    _addAssistantMessage(
      'नमस्ते! 🌱 I am **FarmSaathi AI**, your personal agriculture advisor.\n\n'
      'Ask me anything about:\n'
      '• 🌾 **Best crops** for your land & season\n'
      '• 💊 **Fertilizers & pesticides** guidance\n'
      '• 🐛 **Disease & pest** identification\n'
      '• 📈 **Market prices** & selling tips\n'
      '• 🌧️ **Weather-based** sowing advice\n\n'
      'Type or speak your question!',
    );
  }

  void _addAssistantMessage(String content) {
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isTyping) return;

    // Add user message
    final userMsg = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_u',
      role: MessageRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    // Add loading placeholder
    final loadingId = '${DateTime.now().millisecondsSinceEpoch}_a';
    final loadingMsg = ChatMessage(
      id: loadingId,
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isTyping: true,
    );

    // Build history for GPT (exclude loading msg, limit to last 20)
    final history = state.messages
        .where((m) => !m.isLoading && m.role != MessageRole.system)
        .map((m) => m.toOpenAIMap())
        .toList();

    // Call GPT with real context
    final weather = state.weatherData;
    final response = await openAI.sendMessage(
      messages: history,
      language: state.language.code,
      location: weather?.cityName,
      temperature: weather != null ? '${weather.temperature.toStringAsFixed(1)}°C' : null,
      rainfall: weather?.rainfallLabel,
      humidity: weather != null ? '${weather.humidity.toStringAsFixed(0)}%' : null,
      marketTrend: state.marketContext,
    );

    // Replace loading with real response
    final updatedMessages = state.messages.map((m) {
      if (m.id == loadingId) {
        return m.copyWith(content: response, isLoading: false);
      }
      return m;
    }).toList();

    if (mounted) {
      state = state.copyWith(messages: updatedMessages, isTyping: false);
    }
  }

  void setLanguage(ChatLanguage lang) {
    state = state.copyWith(language: lang);
  }

  void setListening(bool value) {
    state = state.copyWith(isListening: value);
  }

  void clearChat() {
    state = ChatScreenState(
      language: state.language,
      weatherData: state.weatherData,
      marketContext: state.marketContext,
    );
    _addAssistantMessage(
      '🔄 Chat cleared! Ask me anything about farming.\n\n'
      'How can I help you today?',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CHAT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class FarmAIChatScreen extends ConsumerStatefulWidget {
  const FarmAIChatScreen({super.key});

  @override
  ConsumerState<FarmAIChatScreen> createState() => _FarmAIChatScreenState();
}

class _FarmAIChatScreenState extends ConsumerState<FarmAIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttAvailable = false;
  bool _isSpeaking = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initSpeech() async {
    _sttAvailable = await _stt.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _tts.stop();
    _stt.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await ref.read(chatScreenProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _toggleListening() async {
    final notifier = ref.read(chatScreenProvider.notifier);
    final isListening = ref.read(chatScreenProvider).isListening;
    final language = ref.read(chatScreenProvider).language;

    if (isListening) {
      await _stt.stop();
      notifier.setListening(false);
    } else {
      if (!_sttAvailable) return;
      notifier.setListening(true);
      await _stt.listen(
        localeId: language.sttLocale,
        onResult: (result) {
          _inputController.text = result.recognizedWords;
          if (result.finalResult) {
            notifier.setListening(false);
            _send();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _speakMessage(String text, ChatLanguage language) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    await _tts.setLanguage(language.ttsLocale);
    // Strip markdown before speaking
    final plain = text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll('#', '')
        .replaceAll('•', '')
        .trim();
    setState(() => _isSpeaking = true);
    await _tts.speak(plain);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatScreenProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-scroll when new messages arrive
    if (chatState.messages.isNotEmpty) _scrollToBottom();

    final bgColor = isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F4F8);
    final surfaceColor = isDark ? const Color(0xFF161B22) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark, chatState, surfaceColor),
      body: Column(
        children: [
          // ── Weather context banner ──────────────────────────────────────
          if (chatState.weatherData != null)
            _buildWeatherBanner(chatState.weatherData!, isDark),
          // ── Message list ────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final msg = chatState.messages[index];
                return _buildMessageBubble(msg, isDark, chatState.language);
              },
            ),
          ),
          // ── Input area ──────────────────────────────────────────────────
          _buildInputArea(isDark, chatState, surfaceColor),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      bool isDark, ChatScreenState state, Color surface) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        color: AppColors.primary,
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF0D7A5A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FarmSaathi AI',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                state.isTyping ? 'Thinking...' : 'Agriculture Expert',
                style: TextStyle(
                  fontSize: 11,
                  color: state.isTyping ? AppColors.secondary : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Language picker
        PopupMenuButton<ChatLanguage>(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              state.language.label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          onSelected: (lang) {
            ref.read(chatScreenProvider.notifier).setLanguage(lang);
          },
          itemBuilder: (_) => ChatLanguage.values
              .map((l) => PopupMenuItem(
                    value: l,
                    child: Text(l.label),
                  ))
              .toList(),
        ),
        // Clear chat
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          color: Colors.grey,
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Clear Chat?'),
                content: const Text('All messages will be deleted.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(chatScreenProvider.notifier).clearChat();
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeatherBanner(WeatherData data, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1A2332) : const Color(0xFFE8F5E9),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_rounded, color: AppColors.secondary, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${data.cityName}: ${data.temperature.toStringAsFixed(0)}°C  •  '
              '${data.rainfallLabel}  •  ${data.humidity.toStringAsFixed(0)}% humidity',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      ChatMessage msg, bool isDark, ChatLanguage language) {
    final isUser = msg.role == MessageRole.user;

    if (msg.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildAvatar(false),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: _TypingDots(isDark: isDark),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: isUser
                  ? null
                  : () => _speakMessage(msg.content, language),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF0D7A5A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUser
                      ? null
                      : (isDark ? const Color(0xFF1E2D3D) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? AppColors.primary.withAlpha(40)
                          : Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormattedMessageText(
                      text: msg.content,
                      isUser: isUser,
                      isDark: isDark,
                    ),
                    if (!isUser) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _speakMessage(msg.content, language),
                            child: Row(
                              children: [
                                Icon(
                                  _isSpeaking
                                      ? Icons.stop_circle_outlined
                                      : Icons.volume_up_rounded,
                                  size: 14,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _isSpeaking ? 'Stop' : 'Listen',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${msg.timestamp.hour.toString().padLeft(2, '0')}:'
                            '${msg.timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  isDark ? Colors.white30 : Colors.black26,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUser
              ? [const Color(0xFF6C63FF), const Color(0xFF4A47C1)]
              : [AppColors.primary, const Color(0xFF0D7A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.eco_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildInputArea(
      bool isDark, ChatScreenState state, Color surface) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Mic button ─────────────────────────────────────────────
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, child) => Transform.scale(
                scale: state.isListening ? _pulseAnimation.value : 1.0,
                child: child,
              ),
              child: GestureDetector(
                onTap: _sttAvailable ? _toggleListening : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: state.isListening
                        ? Colors.red
                        : AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    state.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: state.isListening ? Colors.white : AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // ── Text input ─────────────────────────────────────────────
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0D1117)
                      : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _inputController,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: state.isListening
                        ? '🎤 Listening...'
                        : 'Ask about crops, weather, market prices...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // ── Send button ────────────────────────────────────────────
            GestureDetector(
              onTap: state.isTyping ? null : _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: state.isTyping
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF0D7A5A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: state.isTyping ? Colors.grey.shade300 : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: state.isTyping
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                ),
                child: state.isTyping
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated Typing Dots ─────────────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  final bool isDark;
  const _TypingDots({required this.isDark});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final opacity = ((t - delay).abs() < 0.33 ? 1.0 : 0.25)
                .clamp(0.25, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: (widget.isDark ? Colors.white : AppColors.primary)
                    .withAlpha((opacity * 255).toInt()),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Formatted Message Text (basic markdown renderer) ─────────────────────────
class _FormattedMessageText extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isDark;

  const _FormattedMessageText({
    required this.text,
    required this.isUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isUser ? Colors.white : (isDark ? Colors.white : Colors.black87);
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => _renderLine(line, baseColor)).toList(),
    );
  }

  Widget _renderLine(String line, Color base) {
    if (line.trim().isEmpty) return const SizedBox(height: 4);

    // Bold headers: **text**
    if (line.trim().startsWith('**') && line.trim().endsWith('**') && !line.trim().contains('**', 2)) {
      final inner = line.trim().replaceAll('**', '');
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Text(inner,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: base,
                fontSize: 14)),
      );
    }

    // Bullet points
    if (line.trim().startsWith('•') ||
        line.trim().startsWith('-') ||
        RegExp(r'^\d+\.').hasMatch(line.trim())) {
      return Padding(
        padding: const EdgeInsets.only(left: 4, top: 2),
        child: _richText(line, base, 13),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: _richText(line, base, 13.5),
    );
  }

  Widget _richText(String line, Color base, double size) {
    // Parse inline **bold** segments
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final match in pattern.allMatches(line)) {
      if (match.start > last) {
        spans.add(TextSpan(
            text: line.substring(last, match.start),
            style: TextStyle(color: base, fontSize: size)));
      }
      spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
              color: base,
              fontSize: size,
              fontWeight: FontWeight.bold)));
      last = match.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(
          text: line.substring(last),
          style: TextStyle(color: base, fontSize: size)));
    }
    return RichText(text: TextSpan(children: spans));
  }
}
