import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';
import 'package:warrior_path/screens/role_selector_screen.dart';
import 'package:warrior_path/screens/student/school_search_screen.dart';
import 'package:warrior_path/screens/wizard_create_school_screen.dart';

import '../../../l10n/app_localizations.dart';
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

          // --- 2. TARJETA AÑADIDA AQUÍ ---
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
        ],
      ),
    );
  }
}
