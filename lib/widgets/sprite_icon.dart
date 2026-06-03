import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Slices one cell from a spritesheet and renders it as a [size]×[size] square.
///
/// Fine-tuning the crop:
///   [cropFraction]  – fraction of min(cellW, cellH) used as the square side.
///                     1.0 = full cell, 0.9 = 90% (adds ~5 % padding per side).
///   [cropOffsetDx]  – horizontal shift as a fraction of cellW
///                     (positive → move crop right, negative → left).
///   [cropOffsetDy]  – vertical shift as a fraction of cellH
///                     (positive → move crop down, negative → up).
class SpriteIcon extends StatefulWidget {
  const SpriteIcon({
    super.key,
    required this.assetPath,
    required this.spriteIndex,
    required this.totalCols,
    required this.totalRows,
    required this.size,
    required this.fallback,
    this.colorFilter,
    this.cropFraction = 1.0,
    this.cropOffsetDx = 0.0,
    this.cropOffsetDy = 0.0,
  });

  final String assetPath;
  final int spriteIndex;
  final int totalCols;
  final int totalRows;
  final double size;
  final Widget fallback;
  final ColorFilter? colorFilter;

  /// Fraction of min(cellW, cellH) used as the square crop side (0–1).
  final double cropFraction;

  /// Horizontal offset of the crop window, as a fraction of cellW.
  final double cropOffsetDx;

  /// Vertical offset of the crop window, as a fraction of cellH.
  final double cropOffsetDy;

  @override
  State<SpriteIcon> createState() => _SpriteIconState();
}

class _SpriteIconState extends State<SpriteIcon> {
  ui.Image? _image;
  bool _failed = false;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachStream();
  }

  @override
  void didUpdateWidget(SpriteIcon old) {
    super.didUpdateWidget(old);
    if (old.assetPath != widget.assetPath) {
      _detachStream();
      _image = null;
      _failed = false;
      _attachStream();
    }
  }

  @override
  void dispose() {
    _detachStream();
    super.dispose();
  }

  void _attachStream() {
    if (_stream != null) return;
    final l = ImageStreamListener(
      (info, _) {
        if (mounted) setState(() => _image = info.image);
      },
      onError: (_, _) {
        if (mounted) setState(() => _failed = true);
      },
    );
    _listener = l;
    _stream = AssetImage(
      widget.assetPath,
    ).resolve(createLocalImageConfiguration(context));
    _stream!.addListener(l);
  }

  void _detachStream() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(child: widget.fallback),
      );
    }
    if (_image == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _SpritePainter(
        image: _image!,
        spriteIndex: widget.spriteIndex,
        totalCols: widget.totalCols,
        totalRows: widget.totalRows,
        colorFilter: widget.colorFilter,
        cropFraction: widget.cropFraction,
        cropOffsetDx: widget.cropOffsetDx,
        cropOffsetDy: widget.cropOffsetDy,
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  const _SpritePainter({
    required this.image,
    required this.spriteIndex,
    required this.totalCols,
    required this.totalRows,
    required this.cropFraction,
    required this.cropOffsetDx,
    required this.cropOffsetDy,
    this.colorFilter,
  });

  final ui.Image image;
  final int spriteIndex;
  final int totalCols;
  final int totalRows;
  final double cropFraction;
  final double cropOffsetDx;
  final double cropOffsetDy;
  final ColorFilter? colorFilter;

  @override
  void paint(Canvas canvas, Size size) {
    final int row = spriteIndex ~/ totalCols;
    final int col = spriteIndex % totalCols;

    // Cell dimensions derived from the actual decoded image.
    final double cellW = image.width / totalCols;
    final double cellH = image.height / totalRows;

    // Square side = min(cellW, cellH) * cropFraction.
    final double side = (cellW < cellH ? cellW : cellH) * cropFraction;

    // Center the crop window inside the cell, then apply the optional offsets.
    final double srcLeft =
        col * cellW + (cellW - side) / 2 + cellW * cropOffsetDx;
    final double srcTop =
        row * cellH + (cellH - side) / 2 + cellH * cropOffsetDy;

    final Rect src = Rect.fromLTWH(srcLeft, srcTop, side, side);
    final Rect dst = Rect.fromLTWH(0, 0, size.width, size.height);

    final Paint paint = Paint()..filterQuality = FilterQuality.high;
    if (colorFilter != null) paint.colorFilter = colorFilter;
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(_SpritePainter old) =>
      old.image != image ||
      old.spriteIndex != spriteIndex ||
      old.cropFraction != cropFraction ||
      old.cropOffsetDx != cropOffsetDx ||
      old.cropOffsetDy != cropOffsetDy ||
      old.colorFilter != colorFilter;
}
