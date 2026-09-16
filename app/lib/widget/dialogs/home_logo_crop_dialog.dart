import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/provider/skin_provider.dart';

class HomeLogoCropDialog extends StatefulWidget {
  static const _previewSize = 220.0;

  final ui.Image image;

  const HomeLogoCropDialog({required this.image, super.key});

  static Future<HomeLogoCrop?> open(BuildContext context, String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();

    if (!context.mounted) {
      frame.image.dispose();
      return null;
    }

    final result = await showDialog<HomeLogoCrop>(
      context: context,
      builder: (_) => HomeLogoCropDialog(image: frame.image),
    );
    frame.image.dispose();
    return result;
  }

  @override
  State<HomeLogoCropDialog> createState() => _HomeLogoCropDialogState();
}

class _HomeLogoCropDialogState extends State<HomeLogoCropDialog> {
  double _zoom = 1;
  double _offsetX = 0;
  double _offsetY = 0;

  void _reset() {
    setState(() {
      _zoom = 1;
      _offsetX = 0;
      _offsetY = 0;
    });
  }

  void _moveImage(DragUpdateDetails details) {
    setState(() {
      _offsetX = (_offsetX - details.delta.dx / HomeLogoCropDialog._previewSize * 2).clamp(-1, 1);
      _offsetY = (_offsetY - details.delta.dy / HomeLogoCropDialog._previewSize * 2).clamp(-1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(t.settingsTab.appearance.homeLogoCropTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onPanUpdate: _moveImage,
                onDoubleTap: _reset,
                child: Container(
                  width: HomeLogoCropDialog._previewSize,
                  height: HomeLogoCropDialog._previewSize,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 3),
                  ),
                  child: ClipOval(
                    child: CustomPaint(
                      painter: _HomeLogoCropPainter(image: widget.image, zoom: _zoom, offsetX: _offsetX, offsetY: _offsetY),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(t.settingsTab.appearance.homeLogoCropHint, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              _CropSlider(
                label: t.settingsTab.appearance.homeLogoCropZoom,
                value: _zoom,
                min: 1,
                max: 4,
                onChanged: (value) => setState(() => _zoom = value),
              ),
              _CropSlider(
                label: t.settingsTab.appearance.homeLogoCropHorizontal,
                value: _offsetX,
                min: -1,
                max: 1,
                onChanged: (value) => setState(() => _offsetX = value),
              ),
              _CropSlider(
                label: t.settingsTab.appearance.homeLogoCropVertical,
                value: _offsetY,
                min: -1,
                max: 1,
                onChanged: (value) => setState(() => _offsetY = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _reset, child: Text(t.settingsTab.appearance.homeLogoCropReset)),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.general.cancel)),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, HomeLogoCrop(zoom: _zoom, offsetX: _offsetX, offsetY: _offsetY));
          },
          child: Text(t.general.confirm),
        ),
      ],
    );
  }
}

class _CropSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _CropSlider({required this.label, required this.value, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _HomeLogoCropPainter extends CustomPainter {
  final ui.Image image;
  final double zoom;
  final double offsetX;
  final double offsetY;

  const _HomeLogoCropPainter({required this.image, required this.zoom, required this.offsetX, required this.offsetY});

  @override
  void paint(Canvas canvas, Size size) {
    final minDimension = math.min(image.width, image.height).toDouble();
    final cropSize = minDimension / zoom.clamp(1, 4);
    final maxLeft = image.width - cropSize;
    final maxTop = image.height - cropSize;
    final left = ((offsetX.clamp(-1, 1) + 1) / 2) * maxLeft;
    final top = ((offsetY.clamp(-1, 1) + 1) / 2) * maxTop;
    final source = Rect.fromLTWH(left, top, cropSize, cropSize);
    final destination = Offset.zero & size;
    canvas.drawImageRect(image, source, destination, Paint()..filterQuality = FilterQuality.high);
  }

  @override
  bool shouldRepaint(_HomeLogoCropPainter oldDelegate) {
    return image != oldDelegate.image || zoom != oldDelegate.zoom || offsetX != oldDelegate.offsetX || offsetY != oldDelegate.offsetY;
  }
}
