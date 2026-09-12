import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Metadata report for compressed field incident imagery
class ImageCompressionResult {
  final Uint8List bytes;
  final int originalBytes;
  final int compressedBytes;
  final int width;
  final int height;
  final bool wasCompressed;

  const ImageCompressionResult({
    required this.bytes,
    required this.originalBytes,
    required this.compressedBytes,
    required this.width,
    required this.height,
    required this.wasCompressed,
  });

  /// Percentage of data size eliminated during compression (e.g. 88.5%)
  double get reductionPercentage =>
      originalBytes > 0 ? (1.0 - (compressedBytes / originalBytes)) * 100.0 : 0.0;

  @override
  String toString() =>
      'ImageCompressionResult(original: ${(originalBytes / 1024).toStringAsFixed(1)} KB, '
      'compressed: ${(compressedBytes / 1024).toStringAsFixed(1)} KB, '
      'saved: ${reductionPercentage.toStringAsFixed(1)}%, '
      'dims: ${width}x$height)';
}

/// Internal payload for isolate-safe computation
class _CompressionTaskParams {
  final Uint8List inputBytes;
  final int maxWidth;
  final int maxHeight;
  final int quality;
  final int minBytesThreshold;

  const _CompressionTaskParams({
    required this.inputBytes,
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
    required this.minBytesThreshold,
  });
}

/// High-Fidelity Incident Evidence Image Compressor for TiyraSense
/// 
/// Optimized for the rugged North Eastern Region (NER) where high-resolution
/// field photos (10MB-20MB) must be transmitted across intermittent 2G/3G networks
/// without losing fine forensic details (road cracks, water markers, warning signs).
class ImageCompressorService {
  static const int defaultMaxWidth = 1920;   // 1080p/Full HD fidelity standard
  static const int defaultMaxHeight = 1920;
  static const int defaultQuality = 82;      // Visually lossless perceptual threshold
  static const int defaultMinThreshold = 350 * 1024; // 350 KB: don't compress already small files

  /// Compresses an in-memory image byte buffer while preserving structural details.
  /// Runs in a background isolate via [compute] to prevent UI stutter.
  static Future<ImageCompressionResult> compressBytes(
    Uint8List rawBytes, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
    int minBytesThreshold = defaultMinThreshold,
  }) async {
    final params = _CompressionTaskParams(
      inputBytes: rawBytes,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
      minBytesThreshold: minBytesThreshold,
    );

    // Run in background isolate on mobile/desktop; run inline on web
    if (kIsWeb) {
      return _executeCompression(params);
    } else {
      return compute(_executeCompression, params);
    }
  }

  /// Compresses a local [File], writes the optimized image to a temporary file,
  /// and returns the optimized [File] ready for Cloudinary upload.
  static Future<File> compressFile(
    File sourceFile, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
    int minBytesThreshold = defaultMinThreshold,
    String? targetDirectoryPath,
  }) async {
    try {
      final fileLength = await sourceFile.length();

      // If file is already below threshold, return original as-is to preserve 100% fidelity
      if (fileLength <= minBytesThreshold) {
        debugPrint('[ImageCompressor] File already lightweight (${(fileLength / 1024).toStringAsFixed(1)} KB). Skipping recompression.');
        return sourceFile;
      }

      final rawBytes = await sourceFile.readAsBytes();
      final result = await compressBytes(
        rawBytes,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
        minBytesThreshold: minBytesThreshold,
      );

      if (!result.wasCompressed) {
        return sourceFile;
      }

      // Write compressed bytes to output file
      final dir = targetDirectoryPath ?? sourceFile.parent.path;
      final tempTimestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = '$dir/cld_opt_$tempTimestamp.jpg';
      final outFile = File(outPath);
      await outFile.writeAsBytes(result.bytes, flush: true);

      debugPrint('[ImageCompressor] ${result.toString()}');
      return outFile;
    } catch (e) {
      debugPrint('[ImageCompressor] Compression fallback triggered: $e');
      // Gracefully fall back to original file if anything fails
      return sourceFile;
    }
  }

  /// The isolated worker function that performs decoding, bicubic resampling, and JPEG encoding
  static ImageCompressionResult _executeCompression(_CompressionTaskParams params) {
    final originalLength = params.inputBytes.lengthInBytes;

    if (originalLength <= params.minBytesThreshold) {
      return ImageCompressionResult(
        bytes: params.inputBytes,
        originalBytes: originalLength,
        compressedBytes: originalLength,
        width: 0,
        height: 0,
        wasCompressed: false,
      );
    }

    // Decode image from raw bytes
    final decoded = img.decodeImage(params.inputBytes);
    if (decoded == null) {
      // Unrecognized image format: pass through safely
      return ImageCompressionResult(
        bytes: params.inputBytes,
        originalBytes: originalLength,
        compressedBytes: originalLength,
        width: 0,
        height: 0,
        wasCompressed: false,
      );
    }

    final origWidth = decoded.width;
    final origHeight = decoded.height;

    // Calculate proportional aspect-ratio scale
    int targetWidth = origWidth;
    int targetHeight = origHeight;

    if (targetWidth > params.maxWidth || targetHeight > params.maxHeight) {
      if (targetWidth > targetHeight) {
        targetHeight = (targetHeight * (params.maxWidth / targetWidth)).round();
        targetWidth = params.maxWidth;
      } else {
        targetWidth = (targetWidth * (params.maxHeight / targetHeight)).round();
        targetHeight = params.maxHeight;
      }
    }

    // Resample using cubic/linear interpolation for optimal sharpness and detail retention
    img.Image processed;
    if (targetWidth != origWidth || targetHeight != origHeight) {
      processed = img.copyResize(
        decoded,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.cubic, // Bicubic maintains edge sharpness for road cracks & signs
      );
    } else {
      processed = decoded;
    }

    // Encode to optimized JPEG with chosen quality
    final compressedBytes = Uint8List.fromList(
      img.encodeJpg(processed, quality: params.quality),
    );

    // If for any bizarre reason compressed bytes ended up larger, keep original
    if (compressedBytes.lengthInBytes >= originalLength) {
      return ImageCompressionResult(
        bytes: params.inputBytes,
        originalBytes: originalLength,
        compressedBytes: originalLength,
        width: origWidth,
        height: origHeight,
        wasCompressed: false,
      );
    }

    return ImageCompressionResult(
      bytes: compressedBytes,
      originalBytes: originalLength,
      compressedBytes: compressedBytes.lengthInBytes,
      width: targetWidth,
      height: targetHeight,
      wasCompressed: true,
    );
  }
}
