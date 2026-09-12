import 'package:flutter/material.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme.dart';
import 'journey_planning_sheet.dart';

class VehicleProfileSheet extends StatefulWidget {
  const VehicleProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const VehicleProfileSheet(),
    );
  }

  @override
  State<VehicleProfileSheet> createState() => _VehicleProfileSheetState();
}

class _VehicleProfileSheetState extends State<VehicleProfileSheet> {
  late VehicleModel _selectedVehicle;
  late CargoModel _selectedCargo;
  int _activeTab = 0; // 0 = Vehicle, 1 = Cargo

  @override
  void initState() {
    super.initState();
    _selectedVehicle = vehicleService.selectedVehicle;
    _selectedCargo = vehicleService.selectedCargo;
  }

  void _saveConfiguration({bool launchRoutePlanner = false}) {
    vehicleService.selectVehicle(_selectedVehicle);
    vehicleService.selectCargo(_selectedCargo);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vehicle profile updated: ${_selectedVehicle.title} · ${_selectedCargo.title}'),
        backgroundColor: AppTheme.primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );

    if (launchRoutePlanner) {
      JourneyPlanningSheet.show(context);
    }
  }

  void _showAddCustomVehicleDialog() {
    final titleController = TextEditingController();
    final categoryController = TextEditingController(text: 'Heavy Multi-Axle · 28 Ton');
    final weightController = TextEditingController(text: '28.0 Tonnes');
    final gradientController = TextEditingController(text: '16% Incline');
    final descController = TextEditingController(text: 'Custom carrier configured for regional corridor');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Custom Vehicle Entry',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(modalCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Name / Model *',
                  hintText: 'e.g. BharatBenz 2823R or Eicher Pro 3019',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Fleet Category',
                  hintText: 'e.g. Multi-Axle Heavy or Medium Cargo',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      decoration: const InputDecoration(
                        labelText: 'Gross Weight',
                        hintText: 'e.g. 28.0 Tonnes',
                        prefixIcon: Icon(Icons.scale_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: gradientController,
                      decoration: const InputDecoration(
                        labelText: 'Max Hill Grade',
                        hintText: 'e.g. 16% Incline',
                        prefixIcon: Icon(Icons.terrain_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Operational Notes',
                  hintText: 'e.g. Engine exhaust brake equipped',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final name = titleController.text.trim();
                  if (name.isEmpty) return;
                  final newVeh = vehicleService.addCustomVehicle(
                    title: name,
                    category: categoryController.text.trim(),
                    grossWeight: weightController.text.trim(),
                    maxGradient: gradientController.text.trim(),
                    desc: descController.text.trim(),
                  );
                  setState(() {
                    _selectedVehicle = newVeh;
                  });
                  Navigator.of(modalCtx).pop();
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Add & Select Vehicle', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomCargoDialog() {
    final titleController = TextEditingController();
    final categoryController = TextEditingController(text: 'Special Consignment');
    final riskController = TextEditingController(text: 'Restricted Incline & Curves');
    final descController = TextEditingController(text: 'High priority special handling shipment');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Custom Cargo Entry',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(modalCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Cargo Description / Title *',
                  hintText: 'e.g. Liquid Nitrogen Tanker or Medical Cold Chain',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Consignment Classification',
                  hintText: 'e.g. Hazardous Liquid or Heavy Machinery',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: riskController,
                decoration: const InputDecoration(
                  labelText: 'Safety & Risk Handling Rule',
                  hintText: 'e.g. Anti-Roll Capped or Cold Chain Priority',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Handling Remarks',
                  hintText: 'e.g. Sensitive to severe road vibration',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final name = titleController.text.trim();
                  if (name.isEmpty) return;
                  final newCargo = vehicleService.addCustomCargo(
                    title: name,
                    category: categoryController.text.trim(),
                    riskPreference: riskController.text.trim(),
                    desc: descController.text.trim(),
                  );
                  setState(() {
                    _selectedCargo = newCargo;
                  });
                  Navigator.of(modalCtx).pop();
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Add & Select Cargo', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicle & Cargo Configuration',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textHigh,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Adapts route clearance, bridge limits, & gradient safety',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLow,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMid),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderLight),

          // Segmented Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.container,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(0, Icons.local_shipping_rounded, 'Vehicle Fleet (${_selectedVehicle.title.split(' ').first})'),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildSegmentButton(1, Icons.inventory_2_outlined, 'Cargo Profile (${_selectedCargo.title.split(' ').first})'),
                  ),
                ],
              ),
            ),
          ),

          // Content List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _activeTab == 0 ? _buildVehicleList() : _buildCargoList(),
            ),
          ),

          // Live Specs Summary Card & Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: const Border(top: BorderSide(color: AppTheme.borderLight)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.container,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_selectedVehicle.icon, color: AppTheme.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${_selectedVehicle.title} · ${_selectedCargo.title}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                                  ),
                                ),
                                if (_selectedVehicle.isCustom || _selectedCargo.isCustom)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('CUSTOM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedVehicle.grossWeight} · Max ${_selectedVehicle.maxGradient}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _saveConfiguration(launchRoutePlanner: false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryBlue)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _saveConfiguration(launchRoutePlanner: true),
                        icon: const Icon(Icons.alt_route_rounded, size: 18),
                        label: const Text('Plan Route', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, IconData icon, String label) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppTheme.primaryBlue : AppTheme.textLow),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textMid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleList() {
    return Column(
      children: [
        // Custom Vehicle Entry CTA
        InkWell(
          onTap: _showAddCustomVehicleDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryBlue, size: 20),
                SizedBox(width: 8),
                Text(
                  '+ Add Custom Vehicle Entry',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primaryBlue),
                ),
              ],
            ),
          ),
        ),

        ...vehicleService.vehicles.map((v) {
          final isSelected = _selectedVehicle.id == v.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.05) : AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                onTap: () => setState(() => _selectedVehicle = v),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.15) : AppTheme.container,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(v.icon, color: isSelected ? AppTheme.primaryBlue : AppTheme.textMid, size: 24),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        v.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (v.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.amber, width: 0.8),
                        ),
                        child: const Text('CUSTOM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.container,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          v.category.split('·').last.trim(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textLow),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.desc, style: const TextStyle(fontSize: 11, color: AppTheme.textLow)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.scale_rounded, size: 13, color: AppTheme.textMid),
                          const SizedBox(width: 4),
                          Text(v.grossWeight.split('(').first.trim(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMid)),
                          const SizedBox(width: 12),
                          const Icon(Icons.terrain_rounded, size: 13, color: AppTheme.textMid),
                          const SizedBox(width: 4),
                          Text(v.maxGradient, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMid)),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textLow,
                  size: 22,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCargoList() {
    return Column(
      children: [
        // Custom Cargo Entry CTA
        InkWell(
          onTap: _showAddCustomCargoDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryBlue, size: 20),
                SizedBox(width: 8),
                Text(
                  '+ Add Custom Cargo Entry',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primaryBlue),
                ),
              ],
            ),
          ),
        ),

        ...vehicleService.cargos.map((c) {
          final isSelected = _selectedCargo.id == c.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.05) : AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                onTap: () => setState(() => _selectedCargo = c),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.15) : AppTheme.container,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(c.icon, color: isSelected ? AppTheme.primaryBlue : AppTheme.textMid, size: 24),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (c.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.amber, width: 0.8),
                        ),
                        child: const Text('CUSTOM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.desc, style: const TextStyle(fontSize: 11, color: AppTheme.textLow)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 13, color: AppTheme.primaryBlue),
                          const SizedBox(width: 4),
                          Text(c.riskPreference, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textLow,
                  size: 22,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
