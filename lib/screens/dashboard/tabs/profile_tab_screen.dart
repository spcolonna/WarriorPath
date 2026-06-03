import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:warrior_path/providers/locale_provider.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';
import 'package:warrior_path/screens/role_selector_screen.dart';
import 'package:warrior_path/screens/student/school_search_screen.dart';
import 'package:warrior_path/screens/wizard_create_school_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../parent/add_child_screen.dart';
import '../../teacher/edit_teacher_profile_screen.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProfileAndActions),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logOut,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l10n.editMyProfile),
            subtitle: Text(l10n.updateProfileInfo),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EditTeacherProfileScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: Text(l10n.switchProfileSchool),
            subtitle: Text(l10n.accessOtherRoles),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.changeLanguage),
            subtitle: Text(l10n.changeLanguageSubtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguagePicker(context, l10n),
          ),
          const Divider(),

          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.escalator_warning, color: Theme.of(context).primaryColor),
              title: Text(l10n.manageChildren),
              subtitle: Text(l10n.manageChildrenSubtitle),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddChildScreen()),
                );
              },
            ),
          ),

          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.search, color: Theme.of(context).primaryColor),
              title: Text(l10n.enrollInAnotherSchool),
              subtitle: Text(l10n.joinAnotherCommunity),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SchoolSearchScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.add_business, color: Theme.of(context).primaryColor),
              title: Text(l10n.createNewSchool),
              subtitle: Text(l10n.expandYourLegacy),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const WizardCreateSchoolScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.grey),
            title: const Text('Política de privacidad'),
            trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
            onTap: () => launchUrl(
              Uri.parse('https://sebastianperez-sketch.github.io/WarriorPath/support.html'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Eliminar mi cuenta', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmDeleteAccount(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Se eliminarán tus datos de acceso. Esta acción no se puede deshacer.\n\n'
          'Los datos de tu escuela y alumnos no se verán afectados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.delete();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por seguridad, cerrá sesión, volvé a iniciarla y luego eliminá la cuenta.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  void _showLanguagePicker(BuildContext context, AppLocalizations l10n) {
    final localeProvider = context.read<LocaleProvider>();
    final current = localeProvider.locale?.languageCode ?? 'es';

    final options = [
      ('es', l10n.languageSpanish, '🇪🇸'),
      ('en', l10n.languageEnglish, '🇺🇸'),
      ('pt', l10n.languagePortuguese, '🇧🇷'),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(l10n.changeLanguage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            for (final (code, label, flag) in options)
              ListTile(
                leading: Text(flag, style: const TextStyle(fontSize: 22)),
                title: Text(label),
                trailing: current == code
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  localeProvider.setLocale(Locale(code));
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
