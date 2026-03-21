import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/models/tryon_preview.dart';
import '../../../../core/widgets/app_network_image.dart';

class PetTryOnPreview extends StatelessWidget {
  const PetTryOnPreview({
    required this.photoPath,
    required this.preview,
    this.isLoading = false,
    this.loadingLabel,
    this.outfitThumbnailUrl,
    super.key,
  });

  final String? photoPath;
  final TryOnPreview? preview;
  final bool isLoading;
  final String? loadingLabel;
  final String? outfitThumbnailUrl;

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
            if (isLoading)
              _GeneratingOverlay(
                label: loadingLabel ?? 'Generating try-on preview',
                outfitThumbnailUrl: outfitThumbnailUrl,
              ),
          ],
        ),
      ),
    );
  }
}

class _GeneratingOverlay extends StatefulWidget {
  const _GeneratingOverlay({required this.label, this.outfitThumbnailUrl});

  final String label;
  final String? outfitThumbnailUrl;

  @override
  State<_GeneratingOverlay> createState() => _GeneratingOverlayState();
}

class _GeneratingOverlayState extends State<_GeneratingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.34),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final wave = math.sin(_controller.value * math.pi * 2);
            final pulse = 1 + (wave * 0.05);
            final sparkleOpacity = 0.5 + ((wave + 1) * 0.2);

            return Center(
              child: Transform.scale(
                scale: pulse,
                child: Container(
                  width: 270,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(
                                0xFFCCFBF1,
                              ).withValues(alpha: 0.8),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 10,
                            child: Opacity(
                              opacity: sparkleOpacity,
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF14B8A6),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            bottom: 10,
                            child: Opacity(
                              opacity: sparkleOpacity,
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF14B8A6),
                                size: 18,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.pets_rounded,
                            size: 42,
                            color: AppColors.primaryDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.outfitThumbnailUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child:
                              widget.outfitThumbnailUrl!.startsWith('assets/')
                              ? Image.asset(
                                  widget.outfitThumbnailUrl!,
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.cover,
                                )
                              : AppNetworkImage(
                                  imageUrl: widget.outfitThumbnailUrl!,
                                  width: 104,
                                  height: 104,
                                ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vertex AI is fitting the selected outfit. Cached looks will reopen faster next time.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.8),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
