import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_compressor_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/offline_storage_service.dart';
import '../services/report_service.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

class HazardReportSheet extends StatefulWidget {
  final VoidCallback? onSubmit;
  final String? initialHazardType;

  const HazardReportSheet({super.key, this.onSubmit, this.initialHazardType});

  static Future<void> show(BuildContext context, {VoidCallback? onSubmit, String? initialHazardType}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HazardReportSheet(onSubmit: onSubmit, initialHazardType: initialHazardType),
    );
  }

  @override
  State<HazardReportSheet> createState() => _HazardReportSheetState();
}

class _HazardReportSheetState extends State<HazardReportSheet> {
  late String _selectedHazard;
  int _selectedSeverity = 0; // 0 = Partial, 1 = Full Blockage, 2 = Shoulder
  final TextEditingController _notesController = TextEditingController();
  String _gpsCoordinates = 'NH-06 KM 42.8 · 26.0124° N, 91.8901° E';
  bool _gpsLocked = true;

  final List<String> _hazardTypes = [
    'Landslide',
    'Flash Flood',
    'Subsidence',
    'Fallen Tree',
    'Debris',
    'Bridge Issue',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialHazardType != null && _hazardTypes.contains(widget.initialHazardType)) {
      _selectedHazard = widget.initialHazardType!;
    } else {
      _selectedHazard = 'Landslide';
    }
    _acquireGps();
  }

  Future<void> _acquireGps() async {
    final loc = await LocationService().getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _gpsCoordinates = '${loc.latitude.toStringAsFixed(4)}° N, ${loc.longitude.toStringAsFixed(4)}° E';
      _gpsLocked = loc.isSuccess;
    });
  }

  String? _attachedPhoto;
  XFile? _capturedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source, BuildContext modalCtx) async {
    Navigator.of(modalCtx).pop();
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        XFile finalImage = image;
        if (!kIsWeb) {
          final compressedFile = await ImageCompressorService.compressFile(File(image.path));
          finalImage = XFile(compressedFile.path);
        }
        final name = finalImage.name.isNotEmpty ? finalImage.name : 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
        setState(() {
          _capturedImage = finalImage;
          _attachedPhoto = name;
        });
      }
    } catch (e) {
      debugPrint('[HazardReportSheet] ImagePicker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera/Gallery access error: $e'),
            backgroundColor: AppTheme.amber,
          ),
        );
      }
    }
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attach Field Evidence Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textHigh),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Text(
              'Field photos are timestamped and geo-verified before broadcast to ASDMA command.',
              style: TextStyle(fontSize: 12, color: AppTheme.textLow, height: 1.4),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.blueLight, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryBlue),
              ),
              title: const Text('Capture with Camera', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Direct GPS-tagged shutter snapshot', style: TextStyle(fontSize: 11)),
              onTap: () => _pickImage(ImageSource.camera, ctx),
            ),
            const Divider(color: AppTheme.borderLight),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.container, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.photo_library_outlined, color: AppTheme.textHigh),
              ),
              title: const Text('Pick from Field Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Select stored incident snapshot', style: TextStyle(fontSize: 11)),
              onTap: () => _pickImage(ImageSource.gallery, ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ResponsiveWrapper(
        maxWidth: 600,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
            boxShadow: AppTheme.navShadow,
          ),
          child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderMed,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Hazard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textHigh,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'GPS-tagged field observation · Synced to Command',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLow,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: AppTheme.borderLight, height: 20),

          // Scrollable Form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // GPS Status Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.container,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _gpsLocked ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                        size: 18,
                        color: _gpsLocked ? AppTheme.green : AppTheme.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _gpsCoordinates,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textHigh,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _gpsLocked ? AppTheme.greenBg : AppTheme.container,
                          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                          border: Border.all(
                            color: _gpsLocked ? AppTheme.green.withValues(alpha: 0.25) : AppTheme.amber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _gpsLocked ? 'GPS LOCKED' : 'SEARCHING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _gpsLocked ? AppTheme.green : AppTheme.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                ListenableBuilder(
                  listenable: offlineStorageService,
                  builder: (context, _) {
                    final isOnline = offlineStorageService.isOnline;
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.greenBg.withValues(alpha: 0.5) : AppTheme.amberBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isOnline ? AppTheme.green.withValues(alpha: 0.3) : AppTheme.amber.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                            size: 16,
                            color: isOnline ? AppTheme.green : AppTheme.amber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isOnline
                                  ? 'Connected · Live ASDMA Supabase sync active'
                                  : 'Offline Mode · Direct GPS Active. Report saved to encrypted local flash & auto-synced when online.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isOnline ? AppTheme.green : AppTheme.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Hazard Type Horizontal Selector
                const Text(
                  'HAZARD TYPE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textLow,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _hazardTypes.map((type) {
                      final isSelected = _selectedHazard == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedHazard = type);
                          },
                          backgroundColor: AppTheme.container,
                          selectedColor: AppTheme.primaryBlue,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppTheme.textHigh,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Severity Toggle
                const Text(
                  'SEVERITY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textLow,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.container,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      _buildSeveritySegment(0, 'Partial Blockage'),
                      _buildSeveritySegment(1, 'Full Road Closure'),
                      _buildSeveritySegment(2, 'Shoulder Only'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Photo Upload Area
                const Text(
                  'EVIDENCE PHOTO (OPTIONAL)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textLow,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showPhotoPicker,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _attachedPhoto != null ? AppTheme.blueLight : AppTheme.container.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _attachedPhoto != null ? AppTheme.primaryBlue : AppTheme.borderMed,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _attachedPhoto != null
                        ? Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _capturedImage != null && !kIsWeb
                                    ? Image.file(
                                        File(_capturedImage!.path),
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          width: 56,
                                          height: 56,
                                          color: AppTheme.container,
                                          child: const Icon(Icons.broken_image_outlined, color: AppTheme.amber, size: 24),
                                        ),
                                      )
                                    : Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: AppTheme.surface,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.borderLight),
                                        ),
                                        child: const Icon(Icons.image_rounded, color: AppTheme.primaryBlue, size: 28),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _attachedPhoto!,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    const Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, size: 13, color: AppTheme.green),
                                        SizedBox(width: 4),
                                        Text('Geo-tagged · Attached', style: TextStyle(fontSize: 11, color: AppTheme.textLow)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel_rounded, color: AppTheme.textLow),
                                onPressed: () => setState(() {
                                  _attachedPhoto = null;
                                  _capturedImage = null;
                                }),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 28, color: AppTheme.primaryBlue),
                              SizedBox(height: 6),
                              Text(
                                'Tap to capture or attach field evidence',
                                style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Notes / Observations
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observations (optional)',
                    hintText: 'Describe conditions, road blockages, or crew needed...',
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 20),

                // Submit CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();

                      final severities = ['Partial Blockage', 'Full Blockage', 'Shoulder Affected'];
                      final severityStr = _selectedSeverity < severities.length ? severities[_selectedSeverity] : 'Partial Blockage';
                      final userName = authProvider.currentUser?.fullName ?? 'Field Reconnaissance';

                      final isOffline = !offlineStorageService.isOnline;

                      // Record report to ReportService (which also adds dynamic alert and queues offline)
                      reportService.addReport(
                        hazardType: _selectedHazard,
                        severity: severityStr,
                        location: _gpsCoordinates,
                        notes: _notesController.text.trim(),
                        photoPath: _capturedImage?.path,
                        workerName: userName,
                        isOffline: isOffline,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isOffline
                                ? 'Report queued in offline flash storage. Will auto-sync to ASDMA database once connected.'
                                : 'Hazard report recorded to your History & synced to ASDMA command',
                          ),
                          backgroundColor: isOffline ? AppTheme.amber : AppTheme.green,
                        ),
                      );

                      // Dispatch system notification
                      NotificationService().showGeneralNotification(
                        title: isOffline ? 'Report Saved Offline' : 'Hazard Report Broadcasted',
                        body: isOffline
                            ? '$_selectedHazard report safely stored on device. Auto-sync armed.'
                            : '$_selectedHazard incident report dispatched to ASDMA command.',
                      );

                      widget.onSubmit?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broadcast_on_personal_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Broadcast Incident Report',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
}

  Widget _buildSeveritySegment(int index, String label) {
    final isSelected = _selectedSeverity == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSeverity = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textMid,
            ),
          ),
        ),
      ),
    );
  }
}
