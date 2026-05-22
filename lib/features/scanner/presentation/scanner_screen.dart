import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/mock_endpoints.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  
  // Simulated camera state for emulators / PC testing
  bool _useSimulator = false;

  // Scanning laser animation
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  // Shutter tap animation
  late AnimationController _shutterController;
  late Animation<double> _shutterAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // Set up Laser scanning animation
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    // Set up Shutter click scale animation
    _shutterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shutterAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _shutterController, curve: Curves.easeOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        setState(() {
          _useSimulator = true;
        });
      }
    } catch (e) {
      debugPrint("⚠️ Camera hardware initialization bypassed: $e. Using simulator fallback.");
      if (mounted) {
        setState(() {
          _useSimulator = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _laserController.dispose();
    _shutterController.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze([String? mockPath]) async {
    _shutterController.forward().then((_) => _shutterController.reverse());
    
    setState(() {
      _isScanning = true;
    });

    try {
      // Simulate leaf scanning pipeline with /api/detect-disease POST simulation
      final scanResult = await MockEndpoints.detectDisease(mockPath ?? "simulated_leaf_image.jpg");

      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        
        // Push Result screen containing dynamic diagnostics
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ScannerResultScreen(result: scanResult),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error communicating with AI detection API. Please retry."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
      if (image != null) {
        _captureAndAnalyze(image.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open photo library.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context, ref);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera preview or High-fidelity Vector Simulator Fallback
          Positioned.fill(
            child: _isCameraInitialized && !_useSimulator
                ? CameraPreview(_cameraController!)
                : _buildViewfinderSimulator(loc),
          ),

          // 2. Translucent Border Grid Frame Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black.withAlpha(128), width: 24),
              ),
              child: Center(
                child: Container(
                  width: size.width * 0.72,
                  height: size.width * 0.72,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          // 3. Scanning Laser Line (Animated overlay)
          if (_isScanning)
            AnimatedBuilder(
              animation: _laserAnimation,
              builder: (context, child) {
                final topOffset = 100 + _laserAnimation.value * (size.height - 300);
                return Positioned(
                  left: 24,
                  right: 24,
                  top: topOffset,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(204),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // 4. Scanning Loader HUD Text
          if (_isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 18),
                      Text(
                        loc.getTranslate('detecting_disease'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Controls Overlay (Shutter button + Gallery upload)
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Upload button
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                  onPressed: _pickFromGallery,
                ),
                
                // Animated Shutter Trigger button
                GestureDetector(
                  onTap: _isScanning ? null : () => _captureAndAnalyze(),
                  child: ScaleTransition(
                    scale: _shutterAnimation,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

                // Simulated / Real camera toggle
                IconButton(
                  icon: Icon(
                    _useSimulator ? Icons.photo_camera : Icons.computer,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      _useSimulator = !_useSimulator;
                    });
                    if (!_useSimulator && !_isCameraInitialized) {
                      _initializeCamera();
                    }
                  },
                ),
              ],
            ),
          ),

          // 6. Camera Instruction Overlay
          Positioned(
            left: 20,
            right: 20,
            top: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                loc.getTranslate('scanner_instruction'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderSimulator(AppLocalizations loc) {
    return Container(
      color: const Color(0xFF141D17),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.energy_savings_leaf, color: Colors.green, size: 100),
            const SizedBox(height: 16),
            const Text(
              'CAMERA VIEWPORT INITIALIZED',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Simulating High-Fidelity Leaf Diagnostics',
              style: TextStyle(color: Colors.green.withAlpha(153), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// SCREEN 4 - Crop Scanning Result screen
// ----------------------------------------------------
class ScannerResultScreen extends ConsumerStatefulWidget {
  final DiseaseScanResult result;
  const ScannerResultScreen({super.key, required this.result});

  @override
  ConsumerState<ScannerResultScreen> createState() => _ScannerResultScreenState();
}

class _ScannerResultScreenState extends ConsumerState<ScannerResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _counterController;
  late Animation<double> _counterAnimation;

  @override
  void initState() {
    super.initState();
    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    
    _counterAnimation = Tween<double>(begin: 0.0, end: widget.result.confidence).animate(
      CurvedAnimation(parent: _counterController, curve: Curves.easeOutCubic),
    );

    _counterController.forward();
  }

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeLocale = ref.watch(localeProvider);
    final isHindi = activeLocale == AppLocale.hi || activeLocale == AppLocale.mr;
    final String resolvedDisease = isHindi ? widget.result.diseaseNameHI : widget.result.diseaseNameEN;
    final List<String> remedies = isHindi ? widget.result.remediesHI : widget.result.remediesEN;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Severity color code configuration
    Color severityColor = AppColors.success;
    if (widget.result.severity == 'Medium') {
      severityColor = AppColors.warning;
    } else if (widget.result.severity == 'High') {
      severityColor = AppColors.error;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis Report (जांच रिपोर्ट)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: severityColor.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bug_report, color: severityColor, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Identified Disease',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            resolvedDisease,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Diagnostic Specs (Confidence + Severity)
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Confidence Rate', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          // Animated counting number
                          AnimatedBuilder(
                            animation: _counterAnimation,
                            builder: (context, child) {
                              return Text(
                                '${_counterAnimation.value.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Severity Level', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: severityColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.result.severity,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Actionable Remedies
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Recommended Treatment Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Column(
              children: List.generate(remedies.length, (index) {
                final step = remedies[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(fontSize: 13, height: 1.45, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Consult Expert Button
            ElevatedButton(
              onPressed: () {
                _showExpertConsultationDialog(context);
              },
              child: const Text('Consult Local Agronomist Expert'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showExpertConsultationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.support_agent, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Consult Crop Expert'),
          ],
        ),
        content: const Text(
          'Connecting you with Dr. Sanjay Patil (Lead Agronomist at Pune KVK Science Center). A real-time voice call / video leaf check is being established. (डॉक्टर पाटिल से जोड़ा जा रहा है...)',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Call Expert'),
          ),
        ],
      ),
    );
  }
}
