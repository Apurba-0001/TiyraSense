import 'package:flutter/material.dart';

enum AppMapType {
  road,
  satellite,
  terrain,
}

class MapLayerSheet extends StatelessWidget {
  final AppMapType currentMapType;
  final bool showAlerts;
  final bool showIncidents;
  final ValueChanged<AppMapType> onMapTypeChanged;
  final ValueChanged<bool> onToggleAlerts;
  final ValueChanged<bool> onToggleIncidents;

  const MapLayerSheet({
    super.key,
    required this.currentMapType,
    required this.showAlerts,
    required this.showIncidents,
    required this.onMapTypeChanged,
    required this.onToggleAlerts,
    required this.onToggleIncidents,
  });

  static Future<void> show({
    required BuildContext context,
    required AppMapType currentMapType,
    required bool showAlerts,
    required bool showIncidents,
    required ValueChanged<AppMapType> onMapTypeChanged,
    required ValueChanged<bool> onToggleAlerts,
    required ValueChanged<bool> onToggleIncidents,
  }) {
    AppMapType activeType = currentMapType;
    bool activeAlerts = showAlerts;
    bool activeIncidents = showIncidents;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return MapLayerSheet(
            currentMapType: activeType,
            showAlerts: activeAlerts,
            showIncidents: activeIncidents,
            onMapTypeChanged: (type) {
              setSheetState(() => activeType = type);
              onMapTypeChanged(type);
            },
            onToggleAlerts: (val) {
              setSheetState(() => activeAlerts = val);
              onToggleAlerts(val);
            },
            onToggleIncidents: (val) {
              setSheetState(() => activeIncidents = val);
              onToggleIncidents(val);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header with Close 'X'
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Map type',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Map Type Options: Road, Satellite, Terrain
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTypeCard(
                type: AppMapType.road,
                label: 'Default',
                subtitle: 'Road view',
                icon: Icons.alt_route_rounded,
                bgColor: const Color(0xFFE0F2FE),
                accentColor: const Color(0xFF0284C7),
              ),
              _buildTypeCard(
                type: AppMapType.satellite,
                label: 'Satellite',
                subtitle: 'Earth imagery',
                icon: Icons.satellite_alt_rounded,
                bgColor: const Color(0xFF1E293B),
                accentColor: const Color(0xFF38BDF8),
              ),
              _buildTypeCard(
                type: AppMapType.terrain,
                label: 'Terrain',
                subtitle: 'Mountain relief',
                icon: Icons.terrain_rounded,
                bgColor: const Color(0xFFE2E8D5),
                accentColor: const Color(0xFF4D7C0F),
              ),
            ],
          ),

          const SizedBox(height: 22),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 18),

          // Map details: Alerts & Incidents
          const Text(
            'Map details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // Alerts Toggle
              Expanded(
                child: _buildDetailCard(
                  label: 'Alerts',
                  subtitle: 'Corridor hazards',
                  icon: Icons.warning_amber_rounded,
                  activeColor: const Color(0xFFF59E0B),
                  isSelected: showAlerts,
                  onTap: () => onToggleAlerts(!showAlerts),
                ),
              ),
              const SizedBox(width: 14),

              // Incidents Toggle
              Expanded(
                child: _buildDetailCard(
                  label: 'Incidents',
                  subtitle: 'Field reports',
                  icon: Icons.report_problem_rounded,
                  activeColor: const Color(0xFFEF4444),
                  isSelected: showIncidents,
                  onTap: () => onToggleIncidents(!showIncidents),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard({
    required AppMapType type,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color accentColor,
  }) {
    final isSelected = currentMapType == type;
    return GestureDetector(
      onTap: () => onMapTypeChanged(type),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                width: isSelected ? 2.8 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(icon, size: 34, color: accentColor),
                ),
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.16) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? activeColor : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: isSelected ? activeColor : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
