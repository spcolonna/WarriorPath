import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../theme/AppColors.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    String currentLanguageCode = localeProvider.locale?.languageCode ?? Localizations.localeOf(context).languageCode;

    if (!['en', 'es', 'pt'].contains(currentLanguageCode)) {
      currentLanguageCode = 'es';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<Locale>(
        value: Locale(currentLanguageCode),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
        isDense: true,
        underline: const SizedBox.shrink(),
        dropdownColor: AppColors.primaryColor,
        items: const [
          DropdownMenuItem(
            value: Locale('en'),
            child: Text("🇺🇸 EN", style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
          DropdownMenuItem(
            value: Locale('es'),
            child: Text("🇪🇸 ES", style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
          DropdownMenuItem(
            value: Locale('pt'),
            child: Text("🇧🇷 PT", style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
        onChanged: (Locale? newLocale) {
          if (newLocale != null) {
            Provider.of<LocaleProvider>(context, listen: false).setLocale(newLocale);
          }
        },
      ),
    );
  }
}
