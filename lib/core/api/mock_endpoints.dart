import 'dart:async';
import 'dart:math';

class WeatherData {
  final double temperature;
  final double humidity;
  final String rainForecast;
  final String condition;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.rainForecast,
    required this.condition,
  });

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'humidity': humidity,
        'rainForecast': rainForecast,
        'condition': condition,
      };

  factory WeatherData.fromJson(Map<dynamic, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      rainForecast: json['rainForecast'] as String,
      condition: json['condition'] as String,
    );
  }
}

class DiseaseScanResult {
  final String diseaseNameEN;
  final String diseaseNameHI;
  final double confidence;
  final String severity; // 'Low', 'Medium', 'High'
  final List<String> remediesEN;
  final List<String> remediesHI;

  DiseaseScanResult({
    required this.diseaseNameEN,
    required this.diseaseNameHI,
    required this.confidence,
    required this.severity,
    required this.remediesEN,
    required this.remediesHI,
  });

  Map<String, dynamic> toJson() => {
        'diseaseNameEN': diseaseNameEN,
        'diseaseNameHI': diseaseNameHI,
        'confidence': confidence,
        'severity': severity,
        'remediesEN': remediesEN,
        'remediesHI': remediesHI,
      };
}

class MockEndpoints {
  static final _random = Random();

  // Simulate fetching weather from OpenWeatherMap API
  static Future<WeatherData> fetchWeather() async {
    await Future.delayed(const Duration(milliseconds: 600)); // Network latency simulator
    
    // Generates localized-friendly weather statistics
    final double temp = 28.0 + _random.nextDouble() * 7; // 28 to 35 C
    final double humid = 60.0 + _random.nextDouble() * 25; // 60% to 85%
    final String forecast = humid > 75 
        ? 'Heavy Rain Forecasted (भारी बारिश की संभावना)' 
        : 'Light showers expected Thursday (गुरुवार को हल्की बौछारें)';
    final String cond = humid > 75 ? 'Rainy' : 'Cloudy';

    return WeatherData(
      temperature: double.parse(temp.toStringAsFixed(1)),
      humidity: double.parse(humid.toStringAsFixed(1)),
      rainForecast: forecast,
      condition: cond,
    );
  }

  // Simulate AI leaf disease detection POST endpoint
  static Future<DiseaseScanResult> detectDisease(String imagePath) async {
    await Future.delayed(const Duration(milliseconds: 1800)); // Simulate server processing time

    final diseases = [
      DiseaseScanResult(
        diseaseNameEN: 'Potato Late Blight',
        diseaseNameHI: 'आलू का पछेती झुलसा रोग',
        confidence: 94.2,
        severity: 'High',
        remediesEN: [
          'Prune and destroy infected leaves immediately.',
          'Apply Copper-based fungicide spray (e.g., Mancozeb) every 7 days.',
          'Improve soil drainage and reduce overhead irrigation.',
        ],
        remediesHI: [
          'संक्रमित पत्तियों को तुरंत काटकर नष्ट कर दें।',
          'हर 7 दिनों में तांबा-आधारित कवकनाशी स्प्रे (जैसे, मैनकोजेब) का प्रयोग करें।',
          'मिट्टी की जल निकासी में सुधार करें और ऊपर से सिंचाई कम करें।',
        ],
      ),
      DiseaseScanResult(
        diseaseNameEN: 'Tomato Leaf Mold',
        diseaseNameHI: 'टमाटर पत्ती मोल्ड रोग',
        confidence: 88.7,
        severity: 'Medium',
        remediesEN: [
          'Increase air circulation around tomatoes by spacing out plants.',
          'Keep foliage dry — water crops strictly at ground level.',
          'Use registered sulfur dust sprays to inhibit spore spread.',
        ],
        remediesHI: [
          'पौधों के बीच दूरी बढ़ाकर टमाटरों के आसपास वायु परिसंचरण बढ़ाएं।',
          'पत्तियों को सूखा रखें - फसलों को केवल जमीन के स्तर पर ही पानी दें।',
          'बीजाणु फैलने से रोकने के लिए पंजीकृत सल्फर डस्ट स्प्रे का उपयोग करें।',
        ],
      ),
      DiseaseScanResult(
        diseaseNameEN: 'Wheat Leaf Rust',
        diseaseNameHI: 'गेहूं का पत्ता गेरुआ रोग',
        confidence: 91.5,
        severity: 'High',
        remediesEN: [
          'Sow rust-resistant crop varieties in the next cycle.',
          'Apply Triazole fungicide (e.g., Tebuconazole) on early warning signs.',
          'Balance nitrogen fertilization — avoid over-fertilizing.',
        ],
        remediesHI: [
          'अगले चक्र में रस्ट-प्रतिरोधी फसल किस्मों की बुवाई करें।',
          'शुरुआती चेतावनी के संकेतों पर ट्राईज़ोल कवकनाशी (जैसे, टेबुकोनाज़ोल) लागू करें।',
          'नाइट्रोजन उर्वरक का संतुलन बनाए रखें - अत्यधिक उर्वरक देने से बचें।',
        ],
      ),
    ];

    // Return a random disease result for high-fidelity scanning interactive mock
    return diseases[_random.nextInt(diseases.length)];
  }
}
