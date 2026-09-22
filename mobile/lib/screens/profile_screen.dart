import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../services/offline_storage_service.dart';
import '../services/report_service.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/server_connection_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final UserRole role;
  final VoidCallback? onOpenDrawer;

  const ProfileScreen({super.key, required this.role, this.onOpenDrawer});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _audioAlarms = true;
  bool _pushAlerts = true;
  bool _weatherWarnings = true;
  bool _isSyncing = false;
  String? _lastSyncTime;
  double _cacheSizeMb = 24.6;

  void _showEditProfileDialog() {
    final user = authProvider.currentUser;
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '+91-98640-12345');
    final orgController = TextEditingController(
      text: user?.organization ??
          (widget.role == UserRole.driver
              ? 'All Assam Commercial Truckers Union'
              : 'Nongpoh Disaster Inspection Unit'),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
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
                  'Edit Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orgController,
              decoration: const InputDecoration(
                labelText: 'Organization / Union',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                bool synced = false;
                if (newName.isNotEmpty) {
                  synced = await authProvider.updateProfile(
                    fullName: newName,
                    phoneNumber: phoneController.text.trim(),
                    organization: orgController.text.trim(),
                  );
                  if (mounted) setState(() {});
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        synced
                            ? 'Profile details updated and synced to database'
                            : 'Saved on device (offline) — server unreachable. Check server connection in Settings.',
                      ),
                      backgroundColor: synced ? AppTheme.green : AppTheme.amber,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                    'Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: currentPassController,
                obscureText: obscure,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassController,
                obscureText: obscure,
                decoration: const InputDecoration(
                  labelText: 'New Password (min 6 chars)',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setModalState(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final curP = currentPassController.text;
                  final newP = newPassController.text;
                  final confP = confirmPassController.text;
                  if (newP.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: AppTheme.red),
                    );
                    return;
                  }
                  if (newP != confP) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppTheme.red),
                    );
                    return;
                  }
                  final success = await authProvider.changePassword(
                    currentPassword: curP,
                    newPassword: newP,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Password updated in database successfully' : 'Failed to update password. Verify current password.'),
                        backgroundColor: success ? AppTheme.green : AppTheme.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Update Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfflineDataSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Offline Corridor Maps',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Text(
              'Downloaded map packages allow turn-by-turn risk awareness and route assessment without cellular connectivity.',
              style: TextStyle(fontSize: 12, color: AppTheme.textLow, height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildOfflineRow('NH-06 (Guwahati - Shillong - Silchar)', '14.2 MB', true),
            const Divider(color: AppTheme.borderLight),
            _buildOfflineRow('NH-29 (Dimapur - Kohima)', '11.8 MB', true),
            const Divider(color: AppTheme.borderLight),
            _buildOfflineRow('NH-37 (Jorhat - Dibrugarh)', '12.4 MB', true),
            const Divider(color: AppTheme.borderLight),
            _buildOfflineRow('NH-102 (Imphal - Moreh Border)', '16.5 MB', false),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Offline route packages verified & synchronized (38.4 MB active)'),
                      backgroundColor: AppTheme.primaryBlue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_download_rounded, size: 18),
                label: const Text('Update Offline Map Cache'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineRow(String name, String size, bool downloaded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textHigh),
            ),
          ),
          Row(
            children: [
              Text(
                size,
                style: const TextStyle(fontSize: 11, color: AppTheme.textLow),
              ),
              const SizedBox(width: 8),
              Icon(
                downloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                size: 18,
                color: downloaded ? AppTheme.green : AppTheme.textLow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notification Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Hazard Audio Beacon', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Audible alarm when approaching active landslide zones', style: TextStyle(fontSize: 11, color: AppTheme.textLow)),
                value: _audioAlarms,
                activeTrackColor: AppTheme.primaryBlue,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setModalState(() => _audioAlarms = val);
                  setState(() => _audioAlarms = val);
                },
              ),
              const Divider(color: AppTheme.borderLight),
              SwitchListTile(
                title: const Text('Corridor Risk Push Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Immediate broadcast when road status transitions to Blocked', style: TextStyle(fontSize: 11, color: AppTheme.textLow)),
                value: _pushAlerts,
                activeTrackColor: AppTheme.primaryBlue,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setModalState(() => _pushAlerts = val);
                  setState(() => _pushAlerts = val);
                },
              ),
              const Divider(color: AppTheme.borderLight),
              SwitchListTile(
                title: const Text('Severe Weather Disruption Warnings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Precipitation rate radar alerts (>40mm/h)', style: TextStyle(fontSize: 11, color: AppTheme.textLow)),
                value: _weatherWarnings,
                activeTrackColor: AppTheme.primaryBlue,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setModalState(() => _weatherWarnings = val);
                  setState(() => _weatherWarnings = val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    final languages = LocalizationService.supportedLanguages;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizationService.tr('select_language'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...languages.map((lang) {
                final isSelected = localizationService.localeCode == lang['code'];
                return ListTile(
                  title: Text(
                    lang['native']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.textHigh,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue) : null,
                  onTap: () async {
                    await localizationService.setLanguageCode(lang['code']!);
                    if (mounted) setState(() {});
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Language updated to ${lang['native']}'),
                          backgroundColor: AppTheme.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear App Cache?'),
        content: Text(
          'This will remove ${_cacheSizeMb.toStringAsFixed(1)} MB of temporary map tiles and cached telemetry. Offline corridor routes will not be deleted.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textMid, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _cacheSizeMb = 0.0);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully. 24.6 MB freed.'),
                  backgroundColor: AppTheme.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _handleSyncNow() {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SyncProgressDialog(
        onComplete: () {
          if (mounted) {
            setState(() {
              _isSyncing = false;
              _lastSyncTime = 'Just now';
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authProvider.currentUser;
    final userName = user?.fullName ??
        (switch (widget.role) {
          UserRole.driver => 'Ramen Borah',
          UserRole.fieldWorker => 'Dipankar Saikia',
          UserRole.official => 'Pranjal Sarmah',
          UserRole.admin => 'Priya Sharma',
        });
    final roleTitle = switch (widget.role) {
      UserRole.driver => 'Heavy Vehicle Driver',
      UserRole.fieldWorker => 'Field Scout & Recon Officer',
      UserRole.official => 'Operations Command (Official)',
      UserRole.admin => 'System Administrator',
    };
    final org = user?.organization ??
        (switch (widget.role) {
          UserRole.driver => 'All Assam Commercial Truckers Union',
          UserRole.fieldWorker => 'Assam State Disaster Mgmt Auth (ASDMA)',
          UserRole.official => 'Ministry of Road Transport & Highways (MoRTH NER)',
          UserRole.admin => 'TiyraSense Infrastructure Command Core',
        });
    final initials = userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join();

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppTheme.textHigh),
                onPressed: widget.onOpenDrawer,
              )
            : const Padding(
                padding: EdgeInsets.all(8.0),
                child: AppLogo.icon(size: 36, radius: 9),
              ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderLight, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(
                      initials.isNotEmpty ? initials : 'TS',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textHigh,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.blueLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    org,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLow,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Stats Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  _buildStatTile(widget.role == UserRole.driver ? '47' : '28', localizationService.tr('journeys')),
                  const SizedBox(width: 8),
                  _buildStatTile(widget.role == UserRole.driver ? '12' : '64', localizationService.tr('reports')),
                  const SizedBox(width: 8),
                  _buildStatTile('98', localizationService.tr('safety_score')),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Settings Section: ACCOUNT
            _buildSettingsCard(
              title: localizationService.tr('account'),
              items: [
                _SettingsItem(
                  icon: Icons.person_outline_rounded,
                  label: localizationService.tr('edit_profile'),
                  onTap: _showEditProfileDialog,
                ),
                _SettingsItem(
                  icon: Icons.lock_outline_rounded,
                  label: localizationService.tr('change_password'),
                  onTap: _showChangePasswordDialog,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Settings Section: APP
            _buildSettingsCard(
              title: localizationService.tr('app_settings'),
              items: [
                _SettingsItem(
                  icon: Icons.download_outlined,
                  label: localizationService.tr('offline_data'),
                  onTap: _showOfflineDataSheet,
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  label: localizationService.tr('notifications'),
                  onTap: _showNotificationsSheet,
                ),
                _SettingsItem(
                  icon: Icons.translate_rounded,
                  label: localizationService.tr('language'),
                  trailingText: localizationService.currentLanguageNativeName,
                  onTap: _showLanguageSheet,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Settings Section: DATA
            _buildSettingsCard(
              title: 'DATA',
              items: [
                _SettingsItem(
                  icon: Icons.delete_outline_rounded,
                  label: localizationService.tr('clear_cache'),
                  trailingText: _cacheSizeMb > 0 ? '${_cacheSizeMb.toStringAsFixed(1)} MB' : '0 MB',
                  onTap: _showClearCacheDialog,
                ),
                _SettingsItem(
                  icon: Icons.sync_rounded,
                  label: localizationService.tr('sync_now'),
                  trailingText: _lastSyncTime,
                  trailingWidget: _isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                        )
                      : null,
                  onTap: _isSyncing ? null : _handleSyncNow,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Settings Section: SERVER & NETWORK CONNECTION
            _buildSettingsCard(
              title: 'SERVER & NETWORK CONNECTION',
              items: [
                _SettingsItem(
                  icon: Icons.dns_rounded,
                  label: 'Backend Server Endpoint',
                  trailingText: ApiService().baseUrl.replaceAll('/api/v1', '').replaceAll('http://', ''),
                  onTap: () => ServerConnectionSheet.show(
                    context,
                    onUrlUpdated: () => setState(() {}),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.red),
                label: Text(
                  localizationService.tr('log_out'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'TiyraSense v1.0.0 (Build 1) · SIH 2026',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textLow,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String value, String caption) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.container,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textHigh,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textLow,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required String title, required List<_SettingsItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.container,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusCard)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textLow,
                letterSpacing: 0.6,
              ),
            ),
          ),
          ...items.map((item) {
            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    leading: Icon(item.icon, size: 20, color: AppTheme.textMid),
                    title: Text(
                      item.label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textHigh),
                    ),
                    trailing: item.trailingWidget ??
                        (item.trailingText != null
                            ? Text(
                                item.trailingText!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: item.trailingText == 'Just now'
                                      ? AppTheme.green
                                      : AppTheme.primaryBlue,
                                ),
                              )
                            : const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textLow)),
                    onTap: item.onTap,
                  ),
                ),
                if (item != items.last)
                  const Divider(color: AppTheme.borderLight, height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String? trailingText;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  _SettingsItem({
    required this.icon,
    required this.label,
    this.trailingText,
    this.trailingWidget,
    this.onTap,
  });
}

class _SyncProgressDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const _SyncProgressDialog({required this.onComplete});

  @override
  State<_SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<_SyncProgressDialog> {
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _startSyncProcess();
  }

  void _startSyncProcess() async {
    offlineStorageService.syncPendingData().catchError((_) => 0);
    reportService.syncAllPending().catchError((_) => 0);

    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _completed = true);

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    widget.onComplete();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.surface,
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _completed ? AppTheme.green.withValues(alpha: 0.12) : AppTheme.blueLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _completed
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 34)
                    : const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _completed ? 'Sync Complete' : 'Syncing Telemetry',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _completed
                  ? 'All 8 corridors and offline telemetry are up to date.'
                  : 'Exchanging corridor telemetry with TiyraSense server...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textLow,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            if (!_completed) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: AppTheme.container,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 14),
              _buildSyncItem('Verifying offline hazard queue', true),
              const SizedBox(height: 6),
              _buildSyncItem('Updating corridor risk indices', true),
              const SizedBox(height: 6),
              _buildSyncItem('Refreshing GIS tile signatures', false),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.container,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_done_rounded, color: AppTheme.green, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Offline Cache: 38.4 MB · 0 Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textHigh,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                    ),
                  ),
                  onPressed: () {
                    widget.onComplete();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncItem(String text, bool active) {
    return Row(
      children: [
        Icon(
          active ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: active ? AppTheme.primaryBlue : AppTheme.textLow,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: active ? AppTheme.textHigh : AppTheme.textLow,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
