import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../config/power_config.dart';
import 'avatar_html_builder.dart';
import 'mini_avatar.dart';

/// Avatar "hero" cabezón renderizado en HTML/CSS dentro de un WebView.
///
/// Se usa sólo en la pantalla principal (un único WebView). Para listas de
/// ranking usar [MiniAvatar], que es nativo y liviano.
///
/// En web (`kIsWeb`), donde `webview_flutter` no está soportado, cae de forma
/// elegante al [MiniAvatar] nativo a mayor tamaño.
class WarriorAvatarView extends StatefulWidget {
  final AvatarGender gender;
  final int power;

  /// Color primario de la escuela (acento de la vincha / kimono).
  final Color schoolColor;

  /// Tono de piel opcional (`#RRGGBB`).
  final String skinHex;

  final double size;

  const WarriorAvatarView({
    super.key,
    required this.gender,
    required this.power,
    required this.schoolColor,
    this.skinHex = '#ffd9b0',
    this.size = 180,
  });

  @override
  State<WarriorAvatarView> createState() => _WarriorAvatarViewState();
}

class _WarriorAvatarViewState extends State<WarriorAvatarView> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _initController();
  }

  @override
  void didUpdateWidget(covariant WarriorAvatarView old) {
    super.didUpdateWidget(old);
    if (!kIsWeb &&
        (old.power != widget.power ||
            old.gender != widget.gender ||
            old.schoolColor != widget.schoolColor ||
            old.skinHex != widget.skinHex)) {
      _controller?.loadHtmlString(_html);
    }
  }

  String get _html => buildAvatarHtml(
        gender: widget.gender,
        power: widget.power,
        schoolColorHex: _hex(widget.schoolColor),
        skinHex: widget.skinHex,
      );

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString(_html);
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || _controller == null) {
      // Fallback: mini-avatar nativo a mayor tamaño.
      return MiniAvatar(
        gender: widget.gender,
        power: widget.power,
        schoolColor: widget.schoolColor,
        size: widget.size * 0.9,
      );
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: WebViewWidget(controller: _controller!),
    );
  }
}
