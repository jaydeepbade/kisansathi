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

class _ScannerResultScreenState extends ConsumerState<ScannerResultScreen> with TickerProviderStateMixin {
  late AnimationController _counterController;
  late Animation<double> _counterAnimation;
  late AnimationController _severityController;
  late Animation<double> _severityAnimation;
  int _selectedTab = 0; // 0 = Treatment, 1 = Organic

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

    _severityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    final double severityValue = widget.result.severity == 'High'
        ? 1.0
        : widget.result.severity == 'Medium'
            ? 0.55
            : 0.2;
    _severityAnimation = Tween<double>(begin: 0.0, end: severityValue).animate(
      CurvedAnimation(parent: _severityController, curve: Curves.easeOut),
    );

    _counterController.forward();
    Future.delayed(const Duration(milliseconds: 200), () => _severityController.forward());
  }

  @override
  void dispose() {
    _counterController.dispose();
    _severityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeLocale = ref.watch(localeProvider);
    final isHindi = activeLocale == AppLocale.hi || activeLocale == AppLocale.mr;
    final String resolvedDisease = isHindi ? widget.result.diseaseNameHI : widget.result.diseaseNameEN;
    final List<String> remedies = isHindi ? widget.result.remediesHI : widget.result.remediesEN;
    final List<String> organics = isHindi ? widget.result.organicSolutionsHI : widget.result.organicSolutionsEN;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color severityColor = AppColors.success;
    String severityLabel = 'Low Risk';
    IconData severityIcon = Icons.check_circle;
    if (widget.result.severity == 'Medium') {
      severityColor = AppColors.warning;
      severityLabel = 'Moderate Risk';
      severityIcon = Icons.warning_amber_rounded;
    } else if (widget.result.severity == 'High') {
      severityColor = AppColors.error;
      severityLabel = 'High Risk';
      severityIcon = Icons.dangerous;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F7FA),
      body: CustomScrollView(
        slivers: [
          // Hero AppBar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: severityColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [severityColor.withAlpha(220), severityColor.withAlpha(140)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Icon(Icons.eco, color: Colors.white.withAlpha(200), size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'AI Diagnosis Report',
                        style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          resolvedDisease,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Confidence + Severity Row
                  Row(
                    children: [
                      // Confidence card
                      Expanded(
                        child: _buildGlassCard(
                          isDark,
                          child: Column(
                            children: [
                              const Text('Confidence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _counterAnimation,
                                      builder: (_, __) => CircularProgressIndicator(
                                        value: _counterAnimation.value / 100,
                                        strokeWidth: 8,
                                        backgroundColor: AppColors.primary.withAlpha(30),
                                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                        strokeCap: StrokeCap.round,
                                      ),
                                    ),
                                    AnimatedBuilder(
                                      animation: _counterAnimation,
                                      builder: (_, __) => Text(
                                        '${_counterAnimation.value.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Severity card
                      Expanded(
                        child: _buildGlassCard(
                          isDark,
                          child: Column(
                            children: [
                              const Text('Severity Level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              Icon(severityIcon, color: severityColor, size: 36),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: severityColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: severityColor, width: 1.5),
                                ),
                                child: Text(
                                  severityLabel,
                                  style: TextStyle(
                                    color: severityColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Severity Meter Bar
                  _buildGlassCard(
                    isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.speed, color: severityColor, size: 18),
                            const SizedBox(width: 8),
                            const Text('Severity Meter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: _severityAnimation,
                          builder: (_, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _severityAnimation.value,
                              minHeight: 14,
                              backgroundColor: Colors.grey.withAlpha(40),
                              valueColor: AlwaysStoppedAnimation(severityColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Low', style: TextStyle(fontSize: 11, color: AppColors.success)),
                            Text('Medium', style: TextStyle(fontSize: 11, color: AppColors.warning)),
                            Text('High', style: TextStyle(fontSize: 11, color: AppColors.error)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab Switch: Chemical | Organic
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTab(0, '💊 Treatment Plan', isDark),
                        _buildTab(1, '🌿 Organic Solutions', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab Content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _selectedTab == 0
                        ? _buildStepsList(remedies, AppColors.primary, isDark, key: const ValueKey('treatment'))
                        : _buildStepsList(organics, Colors.green.shade600, isDark, key: const ValueKey('organic')),
                  ),
                  const SizedBox(height: 20),

                  // Consult Expert Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showExpertConsultationDialog(context),
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Consult Local Agronomist'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, bool isDark) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepsList(List<String> steps, Color color, bool isDark, {Key? key}) {
    return Column(
      key: key,
      children: steps.isEmpty
          ? [
              Center(
                child: Text(
                  'No solutions available.',
                  style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                ),
              )
            ]
          : List.generate(steps.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withAlpha(40)),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: const TextStyle(fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }),
    );
  }

  Widget _buildGlassCard(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12)],
      ),
      child: child,
    );
  }

  void _showExpertConsultationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
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
