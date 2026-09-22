import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ServerConnectionSheet extends StatefulWidget {
  final VoidCallback? onUrlUpdated;

  const ServerConnectionSheet({super.key, this.onUrlUpdated});

  static Future<void> show(BuildContext context, {VoidCallback? onUrlUpdated}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ServerConnectionSheet(onUrlUpdated: onUrlUpdated),
    );
  }

  @override
  State<ServerConnectionSheet> createState() => _ServerConnectionSheetState();
}

class _ServerConnectionSheetState extends State<ServerConnectionSheet> {
  late final TextEditingController _urlController;
  final ApiService _apiService = ApiService();
  bool _isTesting = false;
  Map<String, dynamic>? _testResult;

  static const List<Map<String, String>> _presets = [
    {
      'label': 'USB Cable (ADB Reverse)',
      'url': 'http://127.0.0.1:8000/api/v1',
      'hint': 'Requires: adb reverse tcp:8000 tcp:8000 on laptop',
    },
    {
      'label': 'Laptop Wi-Fi LAN',
      'url': 'http://10.111.29.120:8000/api/v1',
      'hint': 'Direct LAN access over same Wi-Fi network',
    },
    {
      'label': 'Android Emulator',
      'url': 'http://10.0.2.2:8000/api/v1',
      'hint': 'Standard Android Studio emulator gateway',
    },
  ];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _apiService.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _runConnectionTest([String? targetUrl]) async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final url = targetUrl ?? _urlController.text.trim();
    final result = await _apiService.testConnection(url);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = result;
      });
    }
  }

  Future<void> _saveAndApply() async {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) return;

    final normalized = ApiService.normalizeApiUrl(raw);
    await _apiService.setBaseUrl(normalized);
    await ApiService.setGlobalBaseUrl(normalized);

    if (mounted) {
      widget.onUrlUpdated?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server endpoint set to: $normalized'),
          backgroundColor: AppTheme.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.dns_rounded, color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backend Server Settings',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textHigh),
                      ),
                      Text(
                        'Configure host IP for physical phone & laptop sync',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMid),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMid),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // URL input field
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'Active API Base URL',
                hintText: 'http://10.111.29.120:8000/api/v1',
                prefixIcon: const Icon(Icons.link_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Reset to default',
                  onPressed: () {
                    _urlController.text = 'http://127.0.0.1:8000/api/v1';
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Presets
            const Text(
              'QUICK NETWORK PRESETS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textLow, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),

            ..._presets.map((preset) {
              final isCurrent = _urlController.text.trim() == preset['url'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _urlController.text = preset['url']!;
                      _testResult = null;
                    });
                    _runConnectionTest(preset['url']);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppTheme.primaryBlue.withValues(alpha: 0.08) : AppTheme.canvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent ? AppTheme.primaryBlue : AppTheme.borderLight,
                        width: isCurrent ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18,
                          color: isCurrent ? AppTheme.primaryBlue : AppTheme.textLow,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent ? AppTheme.primaryBlue : AppTheme.textHigh,
                                ),
                              ),
                              Text(
                                preset['hint']!,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMid),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // ADB Reverse tip box
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'USB Cable Tunnel Command',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(const ClipboardData(text: 'adb reverse tcp:8000 tcp:8000'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Command copied to clipboard')),
                          );
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.copy_rounded, color: Color(0xFF38BDF8), size: 13),
                            SizedBox(width: 4),
                            Text('Copy', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'adb reverse tcp:8000 tcp:8000',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Run this on your laptop terminal so the phone routes 127.0.0.1 directly to the laptop over USB.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  ),
                ],
              ),
            ),

            // Test Result Card
            if (_testResult != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult!['success'] == true
                      ? AppTheme.green.withValues(alpha: 0.12)
                      : AppTheme.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _testResult!['success'] == true ? AppTheme.green : AppTheme.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResult!['success'] == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      color: _testResult!['success'] == true ? AppTheme.green : AppTheme.red,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _testResult!['message']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _testResult!['success'] == true ? AppTheme.green : AppTheme.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : () => _runConnectionTest(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Test Connection', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAndApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
