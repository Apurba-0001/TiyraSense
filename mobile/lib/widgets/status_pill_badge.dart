import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeStatusType {
  passable,
  caution,
  restricted,
  highRisk,
  blocked,
  online,
  synced,
  pending,
  offline,
}

class StatusPillBadge extends StatelessWidget {
  final BadgeStatusType status;
  final String? customLabel;

  const StatusPillBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    Color bgColor;
    Color borderColor;
    String label;

    switch (status) {
      case BadgeStatusType.passable:
        dotColor = AppTheme.green;
        bgColor = AppTheme.greenBg;
        borderColor = AppTheme.green.withValues(alpha: 0.25);
        label = 'PASSABLE';
        break;
      case BadgeStatusType.caution:
        dotColor = AppTheme.amber;
        bgColor = AppTheme.amberBg;
        borderColor = AppTheme.amber.withValues(alpha: 0.25);
        label = 'CAUTION';
        break;
      case BadgeStatusType.restricted:
        dotColor = AppTheme.orange;
        bgColor = const Color(0xFFFFF7ED);
        borderColor = AppTheme.orange.withValues(alpha: 0.25);
        label = 'RESTRICTED';
        break;
      case BadgeStatusType.highRisk:
        dotColor = AppTheme.red;
        bgColor = AppTheme.redBg;
        borderColor = AppTheme.red.withValues(alpha: 0.25);
        label = 'HIGH RISK';
        break;
      case BadgeStatusType.blocked:
        dotColor = AppTheme.darkRed;
        bgColor = AppTheme.redBg;
        borderColor = AppTheme.darkRed.withValues(alpha: 0.25);
        label = 'BLOCKED';
        break;
      case BadgeStatusType.online:
        dotColor = AppTheme.green;
        bgColor = AppTheme.greenBg;
        borderColor = AppTheme.green.withValues(alpha: 0.20);
        label = 'ONLINE';
        break;
      case BadgeStatusType.synced:
        dotColor = AppTheme.green;
        bgColor = AppTheme.greenBg;
        borderColor = AppTheme.green.withValues(alpha: 0.20);
        label = 'SYNCED';
        break;
      case BadgeStatusType.pending:
        dotColor = AppTheme.amber;
        bgColor = AppTheme.amberBg;
        borderColor = AppTheme.amber.withValues(alpha: 0.20);
        label = 'PENDING';
        break;
      case BadgeStatusType.offline:
        dotColor = AppTheme.textLow;
        bgColor = AppTheme.container;
        borderColor = AppTheme.borderLight;
        label = 'OFFLINE';
        break;
    }

    final displayText = customLabel ?? label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: dotColor,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
