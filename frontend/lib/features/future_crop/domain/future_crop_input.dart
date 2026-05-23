class FutureCropInput {
  final double landSize; // in acres
  final String location;
  final String soilType;
  final String waterAvailability;
  final double budget;
  final String irrigationType;
  final String currentCrop;
  final int farmingExperience; // years

  FutureCropInput({
    required this.landSize,
    required this.location,
    required this.soilType,
    required this.waterAvailability,
    required this.budget,
    required this.irrigationType,
    required this.currentCrop,
    required this.farmingExperience,
  });

  Map<String, dynamic> toJson() => {
        'landSize': landSize,
        'location': location,
        'soilType': soilType,
        'waterAvailability': waterAvailability,
        'budget': budget,
        'irrigationType': irrigationType,
        'currentCrop': currentCrop,
        'farmingExperience': farmingExperience,
      };
}
