import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/models/tryon_preview.dart';

class PetTryOnPreview extends StatelessWidget {
  const PetTryOnPreview({
    required this.photoPath,
    required this.preview,
    this.isLoading = false,
    super.key,
  });

  final String? photoPath;
  final TryOnPreview? preview;
  final bool isLoading;

  Color _parseColor(String hex, [double opacity = 1]) {
    final normalized = hex.replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16) ?? 0x14B8A6;
    return Color(0xFF000000 | value).withValues(alpha: opacity);
  }

  @override
  Widget build(BuildContext context) {
    if (photoPath == null || photoPath!.isEmpty) {
      return Container(
        height: 390,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets_rounded, size: 54, color: Color(0xFF94A3B8)),
              SizedBox(height: 12),
              Text(
                'Add a pet photo in Pet Profile to see the outfit overlay preview.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final previewData = preview;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 390,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (previewData?.generatedImageBytes != null)
              Image.memory(previewData!.generatedImageBytes!, fit: BoxFit.cover)
            else if (photoPath!.startsWith('assets/'))
              Image.asset(photoPath!, fit: BoxFit.cover)
            else
              Image.file(File(photoPath!), fit: BoxFit.cover),
            Container(color: Colors.black.withValues(alpha: 0.08)),
            if (previewData != null && previewData.generatedImageBytes == null)
              CustomPaint(
                painter: _GarmentOverlayPainter(
                  preview: previewData,
                  primaryColor: _parseColor(
                    previewData.primaryColor,
                    previewData.opacity,
                  ),
                  accentColor: _parseColor(
                    previewData.accentColor,
                    math.min(1, previewData.opacity + 0.08),
                  ),
                ),
              ),
            if (previewData == null && isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class _GarmentOverlayPainter extends CustomPainter {
  const _GarmentOverlayPainter({
    required this.preview,
    required this.primaryColor,
    required this.accentColor,
  });

  final TryOnPreview preview;
  final Color primaryColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayWidth = size.width * preview.widthFactor;
    final overlayHeight = size.height * preview.heightFactor;
    final center = Offset(
      size.width * preview.centerX,
      size.height * preview.centerY,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);

    final bodyRect = Rect.fromCenter(
      center: Offset.zero,
      width: overlayWidth,
      height: overlayHeight,
    );
    final bodyPaint = Paint()..color = primaryColor;
    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, overlayWidth * 0.02);

    final bodyPath = Path();
    final neckInset = overlayWidth * preview.neckInset;
    final sleeveDrop = overlayHeight * preview.sleeveDrop;
    final hemCurve = overlayHeight * preview.hemCurve;

    bodyPath.moveTo(bodyRect.left + neckInset, bodyRect.top);
    bodyPath.lineTo(
      bodyRect.left + overlayWidth * 0.1,
      bodyRect.top + sleeveDrop,
    );
    bodyPath.lineTo(bodyRect.left, bodyRect.top + overlayHeight * 0.28);
    bodyPath.lineTo(
      bodyRect.left + overlayWidth * 0.18,
      bodyRect.bottom - hemCurve,
    );
    bodyPath.quadraticBezierTo(
      0,
      bodyRect.bottom + hemCurve,
      bodyRect.right - overlayWidth * 0.18,
      bodyRect.bottom - hemCurve,
    );
    bodyPath.lineTo(bodyRect.right, bodyRect.top + overlayHeight * 0.28);
    bodyPath.lineTo(
      bodyRect.right - overlayWidth * 0.1,
      bodyRect.top + sleeveDrop,
    );
    bodyPath.lineTo(bodyRect.right - neckInset, bodyRect.top);
    bodyPath.quadraticBezierTo(
      0,
      bodyRect.top + overlayHeight * 0.18,
      bodyRect.left + neckInset,
      bodyRect.top,
    );
    bodyPath.close();

    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, accentPaint);

    _paintPattern(canvas, bodyRect, overlayWidth, overlayHeight);

    final collarPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, bodyRect.top + overlayHeight * 0.08),
        width: overlayWidth * 0.34,
        height: overlayHeight * 0.22,
      ),
      math.pi,
      math.pi,
      false,
      collarPaint,
    );

    canvas.restore();
  }

  void _paintPattern(
    Canvas canvas,
    Rect bodyRect,
    double overlayWidth,
    double overlayHeight,
  ) {
    final patternPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.24)
      ..strokeWidth = math.max(2, overlayWidth * 0.02);

    switch (preview.patternStyle) {
      case 'stripe':
        for (var index = -1; index <= 1; index++) {
          final y = bodyRect.top + overlayHeight * (0.34 + index * 0.18);
          canvas.drawLine(
            Offset(bodyRect.left + overlayWidth * 0.18, y),
            Offset(bodyRect.right - overlayWidth * 0.18, y),
            patternPaint,
          );
        }
        break;
      case 'check':
        for (var row = 0; row < 3; row++) {
          final y = bodyRect.top + overlayHeight * (0.28 + row * 0.18);
          canvas.drawLine(
            Offset(bodyRect.left + overlayWidth * 0.16, y),
            Offset(bodyRect.right - overlayWidth * 0.16, y),
            patternPaint,
          );
        }
        for (var column = -1; column <= 1; column++) {
          final x = column * overlayWidth * 0.14;
          canvas.drawLine(
            Offset(x, bodyRect.top + overlayHeight * 0.18),
            Offset(x, bodyRect.bottom - overlayHeight * 0.1),
            patternPaint,
          );
        }
        break;
      case 'dots':
        final dotPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.28)
          ..style = PaintingStyle.fill;
        for (var row = 0; row < 3; row++) {
          for (var column = -1; column <= 1; column++) {
            canvas.drawCircle(
              Offset(
                column * overlayWidth * 0.14,
                bodyRect.top + overlayHeight * (0.3 + row * 0.18),
              ),
              overlayWidth * 0.03,
              dotPaint,
            );
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GarmentOverlayPainter oldDelegate) {
    return oldDelegate.preview != preview ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
