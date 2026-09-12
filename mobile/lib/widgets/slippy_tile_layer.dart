import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'map_layer_sheet.dart';

/// High-performance Web Mercator Slippy Map Tile Layer for Flutter.
/// Provides authentic street, satellite, and terrain tiles like Google Maps.
class SlippyTileLayer extends StatelessWidget {
  final double centerLat;
  final double centerLng;
  final double zoom;
  final Offset panOffset;
  final AppMapType mapType;

  const SlippyTileLayer({
    super.key,
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    this.panOffset = Offset.zero,
    this.mapType = AppMapType.road,
  });

  /// Converts latitude and longitude to world pixel coordinates at a given zoom level.
  static Offset latLngToWorld(double lat, double lng, int z) {
    final scale = 256.0 * math.pow(2, z);
    final clampedLat = lat.clamp(-85.05112878, 85.05112878);
    final clampedLng = lng.clamp(-180.0, 180.0);

    final x = (clampedLng + 180.0) / 360.0 * scale;
    final rad = clampedLat * math.pi / 180.0;
    final sinLat = math.sin(rad);
    final y = (0.5 - math.log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * math.pi)) * scale;
    return Offset(x, y);
  }

  /// Converts world pixel coordinates back to latitude and longitude at a given zoom level.
  static Offset worldToLatLng(double x, double y, int z) {
    final scale = 256.0 * math.pow(2, z);
    final lng = (x / scale) * 360.0 - 180.0;
    final y2 = 0.5 - (y / scale);
    final lat = 90.0 - 360.0 * math.atan(math.exp(-y2 * 2.0 * math.pi)) / math.pi;
    return Offset(lat, lng);
  }

  /// Converts (lat, lng) to screen pixel coordinates matching the tile layout.
  static Offset toScreenCoord({
    required double lat,
    required double lng,
    required double centerLat,
    required double centerLng,
    required double zoom,
    required Size screenSize,
    Offset panOffset = Offset.zero,
  }) {
    final int z = zoom.floor().clamp(1, 19);
    final double subScale = math.pow(2.0, zoom - z).toDouble();

    final centerW = latLngToWorld(centerLat, centerLng, z);
    final targetW = latLngToWorld(lat, lng, z);

    final cx = screenSize.width / 2.0;
    final cy = screenSize.height / 2.0;

    final sx = cx + (targetW.dx - centerW.dx) * subScale + panOffset.dx;
    final sy = cy + (targetW.dy - centerW.dy) * subScale + panOffset.dy;
    return Offset(sx, sy);
  }

  /// Returns the authentic tile URL for Google Maps (Default Road, Satellite Hybrid, or Terrain).
  static String getTileUrl(int z, int x, int y, AppMapType type) {
    final s = (x + y).abs() % 4;
    switch (type) {
      case AppMapType.satellite:
        // Google Maps Satellite Hybrid (authentic imagery + road geometry & labels)
        return 'https://mt$s.google.com/vt/lyrs=y&x=$x&y=$y&z=$z';
      case AppMapType.terrain:
        // Google Maps Terrain (elevation relief shading & topographic contours)
        return 'https://mt$s.google.com/vt/lyrs=p&x=$x&y=$y&z=$z';
      case AppMapType.road:
        // Google Maps Default Road (clean street, highway & junction vectors)
        return 'https://mt$s.google.com/vt/lyrs=m&x=$x&y=$y&z=$z';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size.width <= 0 || size.height <= 0) return const SizedBox.shrink();

        final int z = zoom.floor().clamp(1, 19);
        final double subScale = math.pow(2.0, zoom - z).toDouble();
        final double tileSizeOnScreen = 256.0 * subScale;

        final centerW = latLngToWorld(centerLat, centerLng, z);
        final cx = size.width / 2.0;
        final cy = size.height / 2.0;

        // Viewport bounds in world coordinates
        final leftW = centerW.dx + (-cx - panOffset.dx) / subScale;
        final rightW = centerW.dx + (size.width - cx - panOffset.dx) / subScale;
        final topW = centerW.dy + (-cy - panOffset.dy) / subScale;
        final bottomW = centerW.dy + (size.height - cy - panOffset.dy) / subScale;

        final maxTiles = 1 << z;
        final minTx = (leftW / 256.0).floor().clamp(0, maxTiles - 1);
        final maxTx = (rightW / 256.0).floor().clamp(0, maxTiles - 1);
        final minTy = (topW / 256.0).floor().clamp(0, maxTiles - 1);
        final maxTy = (bottomW / 256.0).floor().clamp(0, maxTiles - 1);

        final Color baseColor = mapType == AppMapType.satellite
            ? const Color(0xFF0A1118)
            : (mapType == AppMapType.terrain ? const Color(0xFFE2E8D5) : const Color(0xFFF1F5F9));

        final List<Widget> tileWidgets = [];

        // Base color background to prevent flashes during network fetches
        tileWidgets.add(
          Positioned.fill(
            child: Container(color: baseColor),
          ),
        );

        // Build visible tile grid (usually 4 to 12 tiles)
        for (int tx = minTx; tx <= maxTx; tx++) {
          for (int ty = minTy; ty <= maxTy; ty++) {
            final double tileScreenX = cx + (tx * 256.0 - centerW.dx) * subScale + panOffset.dx;
            final double tileScreenY = cy + (ty * 256.0 - centerW.dy) * subScale + panOffset.dy;

            final url = getTileUrl(z, tx, ty, mapType);

            tileWidgets.add(
              Positioned(
                left: tileScreenX,
                top: tileScreenY,
                width: tileSizeOnScreen + 0.6, // slight overlap prevents seam line artifacts
                height: tileSizeOnScreen + 0.6,
                child: Image.network(
                  url,
                  headers: const {
                    'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                  },
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: baseColor);
                  },
                ),
              ),
            );
          }
        }

        return Stack(
          fit: StackFit.expand,
          children: tileWidgets,
        );
      },
    );
  }
}
