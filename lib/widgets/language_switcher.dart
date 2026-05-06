import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../theme/AppColors.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    String code = localeProvider.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    if (!['en', 'es', 'pt'].contains(code)) code = 'es';

    return PopupMenuButton<String>(
      color: AppColors.primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      onSelected: (newCode) {
        Provider.of<LocaleProvider>(context, listen: false)
            .setLocale(Locale(newCode));
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'en', child: _LangRow(code: 'en', label: 'English')),
        PopupMenuItem(value: 'es', child: _LangRow(code: 'es', label: 'Español')),
        PopupMenuItem(value: 'pt', child: _LangRow(code: 'pt', label: 'Português')),
      ],
      // Trigger button: cápsula con código + flecha
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniFlag(langCode: code),
            const SizedBox(width: 6),
            Text(
              code.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Fila de cada opción en el popup ──────────────────────────────────────────

class _LangRow extends StatelessWidget {
  final String code;
  final String label;
  const _LangRow({required this.code, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniFlag(langCode: code),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}

// ── Bandera mini dibujada con contenedores ────────────────────────────────────

class _MiniFlag extends StatelessWidget {
  final String langCode;
  const _MiniFlag({required this.langCode});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(width: 26, height: 17, child: _flag()),
    );
  }

  Widget _flag() {
    switch (langCode) {
      case 'en': // EE.UU.: franjas rojas/blancas + cantón azul
        return Stack(
          children: [
            Column(
              children: List.generate(6, (i) => Expanded(
                child: Container(
                  color: i.isEven ? const Color(0xFFBD3D44) : Colors.white,
                ),
              )),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 10,
                height: 9,
                color: const Color(0xFF002868),
              ),
            ),
          ],
        );

      case 'es': // España: rojo / amarillo / rojo
        return Column(
          children: [
            Expanded(child: Container(color: const Color(0xFFAA151B))),
            Expanded(flex: 2, child: Container(color: const Color(0xFFF1BF00))),
            Expanded(child: Container(color: const Color(0xFFAA151B))),
          ],
        );

      case 'pt': // Portugal: verde / rojo
        return Row(
          children: [
            Expanded(flex: 2, child: Container(color: const Color(0xFF006600))),
            Expanded(flex: 3, child: Container(color: const Color(0xFFD52B1E))),
          ],
        );

      default:
        return Container(color: Colors.grey);
    }
  }
}
