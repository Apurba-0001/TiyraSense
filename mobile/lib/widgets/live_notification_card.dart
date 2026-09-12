import 'dart:async';
import 'package:flutter/material.dart';

/// Colorful Google Maps style vector location pin inside white squircle
class GoogleMapsPinWidget extends StatelessWidget {
  final double size;
  const GoogleMapsPinWidget({super.key, this.size = 48.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.68,
          height: size * 0.68,
          child: CustomPaint(
            painter: _GoogleMapsPinPainter(),
          ),
        ),
      ),
    );
  }
}

class _GoogleMapsPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final r = size.width * 0.36;

    // Pin shape outline with 4 Google color regions
    final path = Path();
    path.moveTo(cx, size.height * 0.95);
    path.cubicTo(
      size.width * 0.12,
      size.height * 0.58,
      cx - r,
      size.height * 0.45,
      cx - r,
      cy,
    );
    path.arcToPoint(
      Offset(cx + r, cy),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.cubicTo(
      cx + r,
      size.height * 0.45,
      size.width * 0.88,
      size.height * 0.58,
      cx,
      size.height * 0.95,
    );
    path.close();

    canvas.save();
    canvas.clipPath(path);

    // 1. Red top arch
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cy), redPaint);

    // 2. Yellow right
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    canvas.drawRect(Rect.fromLTWH(cx, 0, cx, size.height), yellowPaint);

    // 3. Green bottom point
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45), greenPaint);

    // 4. Blue left curve
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(0, cy * 0.75, cx, size.height * 0.35), bluePaint);

    canvas.restore();

    // Center white cutout circle
    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.42, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Floating Capsule Live Notification Card (matching user screenshot)
class LiveNotificationCard extends StatelessWidget {
  final String distanceText;
  final String roadName;
  final VoidCallback? onExitNavigation;
  final VoidCallback? onTap;
  final IconData turnIcon;

  const LiveNotificationCard({
    super.key,
    this.distanceText = '20 m',
    this.roadName = 'towards Ramkrishnapur Rd',
    this.onExitNavigation,
    this.onTap,
    this.turnIcon = Icons.turn_right_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final displayRoad = roadName.startsWith('towards') ? roadName : 'towards $roadName';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2838).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Pin | Maneuver text | Turn arrow
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const GoogleMapsPinWidget(size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        distanceText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayRoad,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  turnIcon,
                  size: 38,
                  color: Colors.white,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom Centered "Exit navigation"
            GestureDetector(
              onTap: onExitNavigation,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: const Center(
                  child: Text(
                    'Exit navigation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full Android Lock Screen & Notification Shade modal view
class LiveNotificationLockscreenSheet extends StatefulWidget {
  final String distanceText;
  final String roadName;
  final VoidCallback onExitNavigation;
  final VoidCallback onReturnToMap;

  const LiveNotificationLockscreenSheet({
    super.key,
    required this.distanceText,
    required this.roadName,
    required this.onExitNavigation,
    required this.onReturnToMap,
  });

  static void show(
    BuildContext context, {
    required String distanceText,
    required String roadName,
    required VoidCallback onExitNavigation,
    VoidCallback? onReturnToMap,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LiveNotificationLockscreenSheet(
        distanceText: distanceText,
        roadName: roadName,
        onExitNavigation: onExitNavigation,
        onReturnToMap: onReturnToMap ?? () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<LiveNotificationLockscreenSheet> createState() => _LiveNotificationLockscreenSheetState();
}

class _LiveNotificationLockscreenSheetState extends State<LiveNotificationLockscreenSheet> {
  late Timer _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDate(DateTime dt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
    final w = weekdays[dt.weekday - 1];
    final m = months[dt.month - 1];
    return '$w, ${dt.day} $m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1B3252), // Dusky twilight atmospheric blue
            Color(0xFF13243C),
            Color(0xFF0C1626),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 28,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Top Carrier & System Status Icons: "Jio True5G | Jio" + icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jio True5G | Jio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.alarm_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      const Icon(Icons.sensors_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white70, width: 0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'Vo 5G',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.five_g_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      const Icon(Icons.signal_cellular_alt_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white54, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.bolt_rounded, size: 10, color: Colors.white),
                            SizedBox(width: 1),
                            Text(
                              '77',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Large Digital Clock & Date: "10:38:03  Tue, 8 Sept"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatTime(_now),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(_now),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // "Live notifications" section title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                'Live notifications',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // The exact Live Notification Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LiveNotificationCard(
                distanceText: widget.distanceText,
                roadName: widget.roadName,
                onExitNavigation: widget.onExitNavigation,
                onTap: widget.onReturnToMap,
              ),
            ),

            const Spacer(),

            // Return to live map action pill
            Center(
              child: GestureDetector(
                onTap: widget.onReturnToMap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.touch_app_rounded, size: 14, color: Colors.white70),
                      SizedBox(width: 6),
                      Text(
                        'Tap or swipe down to return to live map',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
