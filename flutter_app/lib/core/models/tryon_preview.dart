import 'dart:convert';
import 'dart:typed_data';

class TryOnPreview {
  const TryOnPreview({
    required this.id,
    required this.overlaySummary,
    required this.previewMode,
    required this.renderer,
    required this.garmentType,
    required this.primaryColor,
    required this.accentColor,
    required this.patternStyle,
    required this.widthFactor,
    required this.heightFactor,
    required this.centerX,
    required this.centerY,
    required this.neckInset,
    required this.hemCurve,
    required this.sleeveDrop,
    required this.opacity,
    required this.label,
    required this.patternSeed,
    this.generatedImageBytes,
    this.generatedImageMimeType,
    this.resultImageUrl,
  });

  final String id;
  final String overlaySummary;
  final String previewMode;
  final String renderer;
  final String garmentType;
  final String primaryColor;
  final String accentColor;
  final String patternStyle;
  final double widthFactor;
  final double heightFactor;
  final double centerX;
  final double centerY;
  final double neckInset;
  final double hemCurve;
  final double sleeveDrop;
  final double opacity;
  final String label;
  final String patternSeed;
  final Uint8List? generatedImageBytes;
  final String? generatedImageMimeType;
  final String? resultImageUrl;

  factory TryOnPreview.fromJson(Map<String, dynamic> json) {
    final renderSpec = json['renderSpec'] as Map<String, dynamic>? ?? const {};

    return TryOnPreview(
      id: json['tryOnId'] as String? ?? '',
      overlaySummary: json['overlaySummary'] as String? ?? '',
      previewMode: json['previewMode'] as String? ?? 'overlay',
      renderer: renderSpec['renderer'] as String? ?? 'overlay-v1',
      garmentType: renderSpec['garmentType'] as String? ?? 'top',
      primaryColor: renderSpec['primaryColor'] as String? ?? '#14B8A6',
      accentColor: renderSpec['accentColor'] as String? ?? '#0F766E',
      patternStyle: renderSpec['patternStyle'] as String? ?? 'solid',
      widthFactor: (renderSpec['widthFactor'] as num?)?.toDouble() ?? 0.45,
      heightFactor: (renderSpec['heightFactor'] as num?)?.toDouble() ?? 0.3,
      centerX: (renderSpec['centerX'] as num?)?.toDouble() ?? 0.5,
      centerY: (renderSpec['centerY'] as num?)?.toDouble() ?? 0.53,
      neckInset: (renderSpec['neckInset'] as num?)?.toDouble() ?? 0.24,
      hemCurve: (renderSpec['hemCurve'] as num?)?.toDouble() ?? 0.12,
      sleeveDrop: (renderSpec['sleeveDrop'] as num?)?.toDouble() ?? 0.1,
      opacity: (renderSpec['opacity'] as num?)?.toDouble() ?? 0.8,
      label: renderSpec['label'] as String? ?? '',
      patternSeed: renderSpec['patternSeed'] as String? ?? 'seed',
      generatedImageBytes: _decodeGeneratedImage(
        json['generatedImageBase64'] as String?,
      ),
      generatedImageMimeType: json['generatedImageMimeType'] as String?,
      resultImageUrl: json['resultImageUrl'] as String?,
    );
  }

  static Uint8List? _decodeGeneratedImage(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}
