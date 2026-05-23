import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLocale { en, hi, mr }

class LocaleNotifier extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    return AppLocale.en;
  }

  void setLocale(AppLocale locale) {
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, AppLocale>(() {
  return LocaleNotifier();
});

class AppLocalizations {
  final AppLocale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context, WidgetRef ref) {
    final activeLocale = ref.watch(localeProvider);
    return AppLocalizations(activeLocale);
  }

  static final Map<AppLocale, Map<String, String>> _localizedValues = {
    AppLocale.en: {
      'app_name': 'FarmSaathi',
      'welcome_farmer': 'Welcome back,',
      'role_farmer': 'Farmer',
      'role_buyer': 'Buyer',
      'role_admin': 'Administrator',
      'role_subtitle': 'Select your role to personalize the app',
      'login_title': 'Verify Your Phone',
      'login_subtitle': 'We will send a 6-digit OTP code to verify your profile.',
      'phone_number': 'Phone Number',
      'send_otp': 'Send Verification Code',
      'verify_otp': 'Verify & Proceed',
      'otp_sent_to': 'OTP sent to ',
      'invalid_otp': 'Invalid OTP, please try again.',
      'onboarding1_title': 'Empowering Smart Farming',
      'onboarding1_desc': 'Get hyper-local weather alerts, AI crop disease scanning, and mandi predictions instantly.',
      'onboarding2_title': 'Direct Local Marketplace',
      'onboarding2_desc': 'Sell your produce directly to buyers with zero middlemen and receive instant bank payments.',
      'onboarding3_title': 'AI Advisory & Insights',
      'onboarding3_desc': 'Access real-time crop disease diagnosis and automated recommendations to double your yields.',
      'skip': 'Skip',
      'next': 'Next',
      'get_started': 'Get Started',
      
      // Dashboard
      'weather_title': 'Weather Forecast',
      'rain_forecast': 'Rain expected soon',
      'humidity': 'Humidity',
      'crop_health_score': 'Crop Health',
      'crop_health_subtitle': 'Overall Field Status',
      'scan_leaf': 'Scan Leaf',
      'list_produce': 'List Produce',
      'check_prices': 'Check Prices',
      'recent_alerts': 'Recent Advisories',
      'alert_blight': 'Late Blight Risk: Potato growers in Pune advisory active.',
      'alert_market': 'Tomato Prices Spike: 25% price increase in Indore Mandi.',
      'alert_weather': 'Heavy Rain Advisory: Shield your harvested grains.',
      'nav_home': 'Home',
      'nav_market': 'Market',
      'nav_scan': 'Scan',
      'nav_analytics': 'Analytics',
      'nav_profile': 'Profile',

      // Marketplace
      'market_title': 'Agri Marketplace',
      'search_placeholder': 'Search crops...',
      'freshness': 'Freshness',
      'chat_farmer': 'Chat',
      'add_to_cart': 'Add to Cart',
      'added_to_cart': 'Added to your Cart!',
      'filter_all': 'All Crops',
      'filter_grains': 'Grains',
      'filter_vegetables': 'Vegetables',
      'filter_fruits': 'Fruits',
      'create_listing': 'List New Produce',
      'crop_name': 'Crop Name',
      'quantity': 'Quantity (kg)',
      'price_kg': 'Asking Price (per kg)',
      'harvest_date': 'Harvest Date',
      'upload_crop_image': 'Upload Crop Image',
      'submit_listing': 'Publish Listing',

      // Scanner
      'scanner_title': 'AI Disease Scanner',
      'scanner_instruction': 'Align the infected leaf inside the frame and capture.',
      'detecting_disease': 'Analyzing Crop Leaf...',
      'disease_result': 'Diagnosis Result',
      'confidence': 'AI Confidence',
      'severity': 'Severity Level',
      'remedies': 'Actionable Remedies',
      'consult_expert': 'Consult Local Expert',
      'camera_error': 'Camera permission denied or camera not found.',

      // Analytics
      'analytics_title': 'Performance Insights',
      'price_trends': 'Price Trends (30d)',
      'yield_analytics': 'Yield Analytics',
      'total_revenue': 'Total Revenue',
      'active_listings': 'Active Listings',
      'price_premium': 'Premium vs Mandi',
      'mandi_price': 'Mandi Price',
      'your_price': 'Your Price',
      'monthly_yield': 'Monthly Yield (kg)',

      // AI Recs
      'ai_recs_title': 'AI recommendations',
      'thumbs_up_toast': 'Thank you! Suggestion upvoted.',
      'thumbs_down_toast': 'Feedback recorded to optimize suggestions.',

      // Profile
      'farm_size': 'Farm Size',
      'crops_grown': 'Crops Grown',
      'aadhaar_verified': 'Aadhaar Verified',
      'lang_settings': 'App Language',
      'notification_settings': 'Receive Push Notifications',
      'bank_account': 'Linked Bank Account',
      'logout': 'Sign Out',

      // New Features
      'voice_assistant': 'Voice Assistant',
      'how_can_i_help': 'How can I help you today?',
      'listening': 'Listening...',
      'advanced_weather': 'Advanced Forecast',
      'soil_moisture': 'Soil Moisture',
      'wind_speed': 'Wind Speed',
      '7_day_forecast': '7-Day Forecast',
      'settings': 'Settings',
      'account_settings': 'Account Settings',
      'app_theme': 'App Theme',
      'help_support': 'Help & Support',
      'future_predictions': 'Future Predictions',
      'sustainability_market': 'Sustainability & Market',
      'sustainability_score': 'Sustainability Score',
      'market_demand': 'Market Demand',
      'shelf_life': 'Est. Shelf Life',
    },
    AppLocale.hi: {
      'app_name': 'फार्मसाथी',
      'welcome_farmer': 'आपका स्वागत है,',
      'role_farmer': 'किसान',
      'role_buyer': 'खरीदार',
      'role_admin': 'प्रशासक',
      'role_subtitle': 'ऐप को व्यक्तिगत बनाने के लिए अपनी भूमिका चुनें',
      'login_title': 'अपना फ़ोन सत्यापित करें',
      'login_subtitle': 'हम आपकी प्रोफ़ाइल को सत्यापित करने के लिए 6-अंकीय ओटीपी कोड भेजेंगे।',
      'phone_number': 'फ़ोन नंबर',
      'send_otp': 'सत्यापन कोड भेजें',
      'verify_otp': 'सत्यापित करें और आगे बढ़ें',
      'otp_sent_to': 'ओटीपी इस नंबर पर भेजा गया: ',
      'invalid_otp': 'अमान्य ओटीपी, कृपया पुन: प्रयास करें।',
      'onboarding1_title': 'स्मार्ट खेती को बढ़ावा',
      'onboarding1_desc': 'मौसम की चेतावनी, एआई फसल रोग स्कैनिंग और मंडी मूल्य भविष्यवाणी तुरंत प्राप्त करें।',
      'onboarding2_title': 'प्रत्यक्ष स्थानीय बाजार',
      'onboarding2_desc': 'बिना किसी बिचौलियों के सीधे खरीदारों को अपनी उपज बेचें और तुरंत भुगतान पाएं।',
      'onboarding3_title': 'एआई सलाह और अंतर्दृष्टि',
      'onboarding3_desc': 'अपनी पैदावार दोगुनी करने के लिए वास्तविक समय में फसल रोग निदान और स्वचालित सलाह प्राप्त करें।',
      'skip': 'छोड़ें',
      'next': 'आगे',
      'get_started': 'शुरू करें',
      
      // Dashboard
      'weather_title': 'मौसम पूर्वानुमान',
      'rain_forecast': 'जल्द ही बारिश की संभावना',
      'humidity': 'आर्द्रता',
      'crop_health_score': 'फसल स्वास्थ्य',
      'crop_health_subtitle': 'खेत की कुल स्थिति',
      'scan_leaf': 'पत्ता स्कैन करें',
      'list_produce': 'फसल सूचीबद्ध करें',
      'check_prices': 'दाम देखें',
      'recent_alerts': 'हालिया सलाह',
      'alert_blight': 'झुलसा रोग का खतरा: पुणे में आलू किसानों के लिए सलाह जारी।',
      'alert_market': 'टमाटर के दाम में उछाल: इंदौर मंडी में 25% की वृद्धि।',
      'alert_weather': 'भारी बारिश की चेतावनी: कटी हुई फसलों को सुरक्षित रखें।',
      'nav_home': 'होम',
      'nav_market': 'बाजार',
      'nav_scan': 'स्कैन',
      'nav_analytics': 'विश्लेषण',
      'nav_profile': 'प्रोफाइल',

      // Marketplace
      'market_title': 'कृषि बाजार',
      'search_placeholder': 'फसलें खोजें...',
      'freshness': 'ताजगी',
      'chat_farmer': 'चैट करें',
      'add_to_cart': 'कार्ट में जोड़ें',
      'added_to_cart': 'कार्ट में जोड़ा गया!',
      'filter_all': 'सभी फसलें',
      'filter_grains': 'अनाज',
      'filter_vegetables': 'सब्जियां',
      'filter_fruits': 'फल',
      'create_listing': 'नई उपज जोडें',
      'crop_name': 'फसल का नाम',
      'quantity': 'मात्रा (किग्रा)',
      'price_kg': 'पूछने की कीमत (प्रति किग्रा)',
      'harvest_date': 'कटाई की तारीख',
      'upload_crop_image': 'फसल की छवि अपलोड करें',
      'submit_listing': 'सूची प्रकाशित करें',

      // Scanner
      'scanner_title': 'एआई रोग स्कैनर',
      'scanner_instruction': 'प्रभावित पत्ते को फ्रेम के अंदर लाएं और कैप्चर करें।',
      'detecting_disease': 'फसल के पत्ते का विश्लेषण किया जा रहा है...',
      'disease_result': 'निदान का परिणाम',
      'confidence': 'एआई सटीकता',
      'severity': 'गंभीरता का स्तर',
      'remedies': 'कारगर उपचार',
      'consult_expert': 'स्थानीय विशेषज्ञ से सलाह लें',
      'camera_error': 'कैमरा अनुमति अस्वीकार कर दी गई है या कैमरा नहीं मिला।',

      // Analytics
      'analytics_title': 'प्रदर्शन अंतर्दृष्टि',
      'price_trends': 'मूल्य रुझान (30 दिन)',
      'yield_analytics': 'पैदावार विश्लेषण',
      'total_revenue': 'कुल आय',
      'active_listings': 'सक्रिय सूचियां',
      'price_premium': 'मंडी दर से प्रीमियम',
      'mandi_price': 'मंडी मूल्य',
      'your_price': 'आपका मूल्य',
      'monthly_yield': 'मासिक उपज (किग्रा)',

      // AI Recs
      'ai_recs_title': 'एआई सिफारिशें',
      'thumbs_up_toast': 'धन्यवाद! सुझाव को पसंद किया गया।',
      'thumbs_down_toast': 'सुझावों को अनुकूलित करने के लिए प्रतिक्रिया दर्ज की गई।',

      // Profile
      'farm_size': 'खेत का आकार',
      'crops_grown': 'उगाई जाने वाली फसलें',
      'aadhaar_verified': 'आधार सत्यापित',
      'lang_settings': 'ऐप की भाषा',
      'notification_settings': 'पुश सूचनाएं प्राप्त करें',
      'bank_account': 'लिंक किया गया बैंक खाता',
      'logout': 'साइन आउट',

      // New Features
      'voice_assistant': 'आवाज़ सहायक',
      'how_can_i_help': 'मैं आपकी कैसे मदद कर सकता हूँ?',
      'listening': 'सुन रहा हूँ...',
      'advanced_weather': 'उन्नत पूर्वानुमान',
      'soil_moisture': 'मिट्टी की नमी',
      'wind_speed': 'हवा की गति',
      '7_day_forecast': '7-दिवसीय पूर्वानुमान',
      'settings': 'सेटिंग्स',
      'account_settings': 'खाता सेटिंग्स',
      'app_theme': 'ऐप थीम',
      'help_support': 'मदद और समर्थन',
      'future_predictions': 'भविष्यवाणियां',
      'sustainability_market': 'स्थिरता और बाजार',
      'sustainability_score': 'स्थिरता स्कोर',
      'market_demand': 'बाजार की मांग',
      'shelf_life': 'अनुमानित शेल्फ जीवन',
    },
    AppLocale.mr: {
      'app_name': 'फार्मसाथी',
      'welcome_farmer': 'तुमचे स्वागत आहे,',
      'role_farmer': 'शेतकरी',
      'role_buyer': 'खरेदीदार',
      'role_admin': 'प्रशासक',
      'role_subtitle': 'ॲप वैयक्तिकृत करण्यासाठी तुमची भूमिका निवडा',
      'login_title': 'तुमचा फोन सत्यापित करा',
      'login_subtitle': 'तुमचे प्रोफाइल सत्यापित करण्यासाठी आम्ही ६-अंकी ओटिपी पाठवू.',
      'phone_number': 'फोन नंबर',
      'send_otp': 'सत्यापन कोड पाठवा',
      'verify_otp': 'सत्यापित करा आणि पुढे जा',
      'otp_sent_to': 'ओटीपी या नंबरवर पाठवला: ',
      'invalid_otp': 'अवैध ओटीपी, कृपया पुन्हा प्रयत्न करा.',
      'onboarding1_title': 'स्मार्ट शेतीला चालना',
      'onboarding1_desc': 'हवामान चेतावणी, एआय पीक रोग स्कॅनिंग आणि बाजार भाव भाकीत त्वरित मिळवा.',
      'onboarding2_title': 'थेट स्थानिक बाजारपेठ',
      'onboarding2_desc': 'कोणत्याही मध्यस्थांशिवाय थेट ग्राहकांना तुमचे उत्पादन विका आणि त्वरित पैसे मिळवा.',
      'onboarding3_title': 'एआय सल्ला आणि अंतर्दृष्टी',
      'onboarding3_desc': 'तुमचे उत्पादन दुप्पट करण्यासाठी रिअल-टाइम पीक रोग निदान आणि स्वयंचलित सल्ला मिळवा.',
      'skip': 'वगळा',
      'next': 'पुढे',
      'get_started': 'सुरू करा',
      
      // Dashboard
      'weather_title': 'हवामान अंदाज',
      'rain_forecast': 'लवकरच पावसाची शक्यता',
      'humidity': 'आद्रता',
      'crop_health_score': 'पीक आरोग्य',
      'crop_health_subtitle': 'शेताची एकूण स्थिती',
      'scan_leaf': 'पान स्कॅन करा',
      'list_produce': 'उत्पादन जोडा',
      'check_prices': 'दर तपासा',
      'recent_alerts': 'नुकत्याच मिळालेल्या सुचना',
      'alert_blight': 'करपा रोगाचा धोका: पुणे येथील बटाटा उत्पादकांसाठी सल्ला जारी.',
      'alert_market': 'टोमॅटो दरात उसळी: इंदूर मंडईत २५% वाढ.',
      'alert_weather': 'मुसळधार पावसाचा इशारा: काढणी केलेले धान्य सुरक्षित ठेवा.',
      'nav_home': 'होम',
      'nav_market': 'बाजार',
      'nav_scan': 'स्कॅन',
      'nav_analytics': 'विश्लेषण',
      'nav_profile': 'प्रोफाइल',

      // Marketplace
      'market_title': 'कृषी बाजारपेठ',
      'search_placeholder': 'पिके शोधा...',
      'freshness': 'ताजेपणा',
      'chat_farmer': 'चॅट करा',
      'add_to_cart': 'कार्टमध्ये जोडा',
      'added_to_cart': 'कार्टमध्ये जोडले गेले!',
      'filter_all': 'सर्व पिके',
      'filter_grains': 'धान्य',
      'filter_vegetables': 'भाज्या',
      'filter_fruits': 'फळे',
      'create_listing': 'नवीन उत्पादन जोडा',
      'crop_name': 'पिकाचे नाव',
      'quantity': 'प्रमाण (किलो)',
      'price_kg': 'अपेक्षित किंमत (प्रति किलो)',
      'harvest_date': 'काढणीची तारीख',
      'upload_crop_image': 'पिकाचा फोटो अपलोड करा',
      'submit_listing': 'यादी प्रकाशित करा',

      // Scanner
      'scanner_title': 'एआय रोग स्कॅनर',
      'scanner_instruction': 'बाधित पान फ्रेमच्या आत आणा आणि फोटो काढा.',
      'detecting_disease': 'पिकाच्या पानावरील रोगाचे विश्लेषण होत आहे...',
      'disease_result': 'निदानाचे निकाल',
      'confidence': 'एआय अचूकता',
      'severity': 'गंभीरतेची पातळी',
      'remedies': 'कारवाईचे उपाय',
      'consult_expert': 'स्थानिक तज्ञाचा सल्ला घ्या',
      'camera_error': 'कॅмера परवानगी नाकारली आहे किंवा कॅमेरा सापडला नाही.',

      // Analytics
      'analytics_title': 'कार्यप्रदर्शन अंतर्दृष्टी',
      'price_trends': 'किंमतीचे ट्रेंड (३० दिवस)',
      'yield_analytics': 'उत्पादन विश्लेषण',
      'total_revenue': 'एकूण उत्पन्न',
      'active_listings': 'सक्रिय याद्या',
      'price_premium': 'मंडी दरापेक्षा जास्तीचा नफा',
      'mandi_price': 'मंडी दर',
      'your_price': 'तुमचा दर',
      'monthly_yield': 'मासिक उत्पादन (किलो)',

      // AI Recs
      'ai_recs_title': 'एआय शिफारसी',
      'thumbs_up_toast': 'धन्यवाद! शिफारस आवडली.',
      'thumbs_down_toast': 'शिफारस सुधारण्यासाठी तुमचा अभिप्राय नोंदवला गेला.',

      // Profile
      'farm_size': 'शेताचा आकार',
      'crops_grown': 'पिकवली जाणारी पिके',
      'aadhaar_verified': 'आधार सत्यापित',
      'lang_settings': 'ॲपची भाषा',
      'notification_settings': 'पुश सूचना मिळवा',
      'bank_account': 'लिंक केलेले बँक खाते',
      'logout': 'साइन आउट',

      // New Features
      'voice_assistant': 'आवाज सहाय्यक',
      'how_can_i_help': 'मी तुमची कशी मदत करू शकतो?',
      'listening': 'ऐकत आहे...',
      'advanced_weather': 'प्रगत अंदाज',
      'soil_moisture': 'मातीतील ओलावा',
      'wind_speed': 'वाऱ्याचा वेग',
      '7_day_forecast': '७ दिवसांचा अंदाज',
      'settings': 'सेटिंग्ज',
      'account_settings': 'खाते सेटिंग्ज',
      'app_theme': 'ॲप थीम',
      'help_support': 'मदत आणि समर्थन',
      'future_predictions': 'भविष्यातील अंदाज',
      'sustainability_market': 'टिकाऊपणा आणि बाजार',
      'sustainability_score': 'टिकाऊपणा स्कोअर',
      'market_demand': 'बाजाराची मागणी',
      'shelf_life': 'अंदाजित शेल्फ लाइफ',
    }
  };

  String getTranslate(String key) {
    return _localizedValues[locale]?[key] ?? _localizedValues[AppLocale.en]?[key] ?? key;
  }
}
