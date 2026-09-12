import 'package:flutter/material.dart';

class VehicleModel {
  final String id;
  final String title;
  final String category;
  final String grossWeight;
  final String maxGradient;
  final String telematicsStatus;
  final String desc;
  final IconData icon;
  final bool isCustom;

  const VehicleModel({
    required this.id,
    required this.title,
    required this.category,
    required this.grossWeight,
    required this.maxGradient,
    required this.telematicsStatus,
    required this.desc,
    required this.icon,
    this.isCustom = false,
  });
}

class CargoModel {
  final String id;
  final String title;
  final String category;
  final String riskPreference;
  final String desc;
  final IconData icon;
  final bool isCustom;

  const CargoModel({
    required this.id,
    required this.title,
    required this.category,
    required this.riskPreference,
    required this.desc,
    required this.icon,
    this.isCustom = false,
  });
}

class VehicleService extends ChangeNotifier {
  static const List<VehicleModel> defaultVehicles = [
    VehicleModel(
      id: 'veh-tata-31t',
      title: 'Tata Prima 31T',
      category: 'Heavy Multi-Axle · 31 Ton',
      grossWeight: '31.0 Tonnes (Loaded: 28.4T)',
      maxGradient: '14% Sustained Incline',
      telematicsStatus: 'Active (0.2s latency)',
      desc: 'High gross weight. Restricted on fragile hill bridges and sharp hairpins.',
      icon: Icons.local_shipping_rounded,
    ),
    VehicleModel(
      id: 'veh-ashok-1618',
      title: 'Ashok Leyland 1618',
      category: 'Medium Cargo Truck · 16 Ton',
      grossWeight: '16.2 Tonnes (Loaded: 14.8T)',
      maxGradient: '18% Sustained Incline',
      telematicsStatus: 'Active (0.3s latency)',
      desc: 'Standard 2-axle carrier. Suitable for regional NH corridors.',
      icon: Icons.fire_truck_outlined,
    ),
    VehicleModel(
      id: 'veh-bolero-maxi',
      title: 'Mahindra Bolero Maxi',
      category: '4x4 Utility Logistics · 2.5 Ton',
      grossWeight: '3.2 Tonnes (Loaded: 2.8T)',
      maxGradient: '28% Mountain Grade',
      telematicsStatus: 'Active (0.1s latency)',
      desc: 'High hill clearance. Capable of navigating unpaved detour bypasses.',
      icon: Icons.directions_car_rounded,
    ),
    VehicleModel(
      id: 'veh-tata-407',
      title: 'Tata 407 LCV',
      category: 'Light Commercial · 4 Ton',
      grossWeight: '5.5 Tonnes (Loaded: 4.8T)',
      maxGradient: '22% Mountain Grade',
      telematicsStatus: 'Active (0.2s latency)',
      desc: 'Agile mountain courier. Rapid transit for priority small parcels.',
      icon: Icons.delivery_dining_outlined,
    ),
    VehicleModel(
      id: 'veh-amb-4wd',
      title: 'Emergency 4WD Ambulance',
      category: 'Disaster / Convoy Escort',
      grossWeight: '2.8 Tonnes (Loaded: 2.5T)',
      maxGradient: '30% Extreme Incline',
      telematicsStatus: 'Active (Priority Green Channel)',
      desc: 'Priority green-channel routing. Cleared for all passable corridors.',
      icon: Icons.medical_services_outlined,
    ),
  ];

  static const List<CargoModel> defaultCargos = [
    CargoModel(
      id: 'cargo-fmcg',
      title: 'FMCG Critical',
      category: 'Standard Fast-Moving Freight',
      riskPreference: 'Balanced 85% Safety Baseline',
      desc: 'Balanced optimization with 85% safety baseline.',
      icon: Icons.inventory_2_outlined,
    ),
    CargoModel(
      id: 'cargo-med',
      title: 'Medical & Disaster Relief',
      category: 'Life-Critical Consignment',
      riskPreference: 'Max Safety · Avoid Landslides',
      desc: 'Highest safety preference. Completely circumvents high-risk landslide zones.',
      icon: Icons.emergency_outlined,
    ),
    CargoModel(
      id: 'cargo-pol',
      title: 'Petroleum & POL Tanker',
      category: 'Flammable Bulk Liquid',
      riskPreference: 'Gradient Capped · Fire Safe',
      desc: 'Strict hill incline restrictions. Avoids steep serpentine gradients.',
      icon: Icons.water_drop_outlined,
    ),
    CargoModel(
      id: 'cargo-agri',
      title: 'Agricultural Perishables',
      category: 'Temperature-Sensitive Cold Chain',
      riskPreference: 'Low Roughness · Speed Optimized',
      desc: 'Balances travel time against surface road degradation.',
      icon: Icons.eco_outlined,
    ),
    CargoModel(
      id: 'cargo-heavy',
      title: 'Heavy Construction Materials',
      category: 'Oversized / High Axle Load',
      riskPreference: 'Bridge Load Verified',
      desc: 'Checks bridge load capacities and culvert integrity.',
      icon: Icons.hardware_outlined,
    ),
  ];

  final List<VehicleModel> _vehicles = List.from(defaultVehicles);
  final List<CargoModel> _cargos = List.from(defaultCargos);

  late VehicleModel _selectedVehicle;
  late CargoModel _selectedCargo;

  VehicleService() {
    _selectedVehicle = _vehicles[0];
    _selectedCargo = _cargos[0];
  }

  List<VehicleModel> get vehicles => List.unmodifiable(_vehicles);
  List<CargoModel> get cargos => List.unmodifiable(_cargos);

  static List<VehicleModel> get availableVehicles => vehicleService.vehicles;
  static List<CargoModel> get availableCargos => vehicleService.cargos;

  VehicleModel get selectedVehicle => _selectedVehicle;
  CargoModel get selectedCargo => _selectedCargo;

  void selectVehicle(VehicleModel vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  void selectVehicleByTitle(String title) {
    final clean = title.trim();
    final index = _vehicles.indexWhere((v) => v.title.toLowerCase() == clean.toLowerCase());
    if (index != -1) {
      _selectedVehicle = _vehicles[index];
    } else {
      addCustomVehicle(
        title: clean,
        category: 'Custom Carrier',
        grossWeight: 'Custom Rated Weight',
        maxGradient: 'Standard 18% Grade',
      );
    }
    notifyListeners();
  }

  void selectCargo(CargoModel cargo) {
    _selectedCargo = cargo;
    notifyListeners();
  }

  void selectCargoByTitle(String title) {
    final clean = title.trim();
    final index = _cargos.indexWhere((c) => c.title.toLowerCase() == clean.toLowerCase());
    if (index != -1) {
      _selectedCargo = _cargos[index];
    } else {
      addCustomCargo(
        title: clean,
        category: 'Custom Consignment',
        riskPreference: 'Dynamic Safety Baseline',
      );
    }
    notifyListeners();
  }

  VehicleModel addCustomVehicle({
    required String title,
    required String category,
    required String grossWeight,
    required String maxGradient,
    String desc = 'Custom fleet profile configured by operator',
    IconData icon = Icons.local_shipping_rounded,
  }) {
    final newVehicle = VehicleModel(
      id: 'custom-veh-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      category: category.trim(),
      grossWeight: grossWeight.trim(),
      maxGradient: maxGradient.trim(),
      telematicsStatus: 'Active (Custom Entry)',
      desc: desc.trim(),
      icon: icon,
      isCustom: true,
    );
    _vehicles.insert(0, newVehicle);
    _selectedVehicle = newVehicle;
    notifyListeners();
    return newVehicle;
  }

  CargoModel addCustomCargo({
    required String title,
    required String category,
    required String riskPreference,
    String desc = 'Custom cargo specifications configured by operator',
    IconData icon = Icons.inventory_2_outlined,
  }) {
    final newCargo = CargoModel(
      id: 'custom-cargo-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      category: category.trim(),
      riskPreference: riskPreference.trim(),
      desc: desc.trim(),
      icon: icon,
      isCustom: true,
    );
    _cargos.insert(0, newCargo);
    _selectedCargo = newCargo;
    notifyListeners();
    return newCargo;
  }
}

final vehicleService = VehicleService();
