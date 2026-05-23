import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/presentation/voice_assistant_widget.dart';
import '../domain/future_crop_input.dart';

// Provider for handling form submission and mock AI response
final futureCropProvider = StateNotifierProvider<FutureCropNotifier, AsyncValue<String>>((ref) => FutureCropNotifier());

class FutureCropNotifier extends StateNotifier<AsyncValue<String>> {
  FutureCropNotifier() : super(const AsyncData(''));

  Future<void> submit(FutureCropInput input) async {
    state = const AsyncLoading();
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));
    // Mock recommendation based on simple logic
    final recommendation = 'Based on your inputs, we recommend growing ${_suggestCrop(input)} for maximum profit.';
    state = AsyncData(recommendation);
  }

  String _suggestCrop(FutureCropInput input) {
    // Very naive mock: if waterAvailability == 'Low' suggest 'Millet', else 'Wheat'
    if (input.waterAvailability.toLowerCase().contains('low')) {
      return 'Millet';
    }
    return 'Wheat';
  }
}

class FutureCropScreen extends ConsumerWidget {
  const FutureCropScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    // Controllers
    final landSizeCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final soilTypeCtrl = TextEditingController();
    final waterAvailCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final irrigationCtrl = TextEditingController();
    final currentCropCtrl = TextEditingController();
    final experienceCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Future Crop Intelligence Engine', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'AI Voice Assistant',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: AppColors.primary, size: 22),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const VoiceAssistantWidget(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _glassInputField('Land Size (acres)', landSizeCtrl, TextInputType.number),
                _glassInputField('Location', locationCtrl, TextInputType.text),
                _glassInputField('Soil Type', soilTypeCtrl, TextInputType.text),
                _glassInputField('Water Availability', waterAvailCtrl, TextInputType.text),
                _glassInputField('Budget (INR)', budgetCtrl, TextInputType.number),
                _glassInputField('Irrigation Type', irrigationCtrl, TextInputType.text),
                _glassInputField('Current Crop', currentCropCtrl, TextInputType.text),
                _glassInputField('Farming Experience (years)', experienceCtrl, TextInputType.number),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final input = FutureCropInput(
                        landSize: double.parse(landSizeCtrl.text),
                        location: locationCtrl.text,
                        soilType: soilTypeCtrl.text,
                        waterAvailability: waterAvailCtrl.text,
                        budget: double.parse(budgetCtrl.text),
                        irrigationType: irrigationCtrl.text,
                        currentCrop: currentCropCtrl.text,
                        farmingExperience: int.parse(experienceCtrl.text),
                      );
                      ref.read(futureCropProvider.notifier).submit(input);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Run AI Analysis'),
                ),
                const SizedBox(height: 16),
                Consumer(builder: (context, ref, _) {
                  final asyncResult = ref.watch(futureCropProvider);
                  return asyncResult.when(
                    data: (msg) => msg.isNotEmpty ? Card(
                      color: AppColors.surfaceDark,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(msg, style: const TextStyle(color: Colors.white)),
                      ),
                    ) : const SizedBox.shrink(),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassInputField(String label, TextEditingController controller, TextInputType type) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }
}
