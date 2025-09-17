import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/schedule/schedule_management_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../teacher/events/event_management_screen.dart';
import '../../teacher/management/edit_school_data_screen.dart';
import '../../teacher/management/finance_management_screen.dart';
import '../../teacher/management/level_management_screen.dart';
import '../../teacher/management/technique_management_screen.dart';

class ManagementTabScreen extends StatelessWidget {
  const ManagementTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final schoolId = Provider.of<SessionProvider>(context).activeSchoolId;

    if (schoolId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.schoolManagement)),
        body: Center(child: Text(l10n.noActiveSchoolError)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.schoolManagement),
      ),
      body: ListView(
        children: [
          _buildManagementTile(
            context: context,
            icon: Icons.event,
            title: l10n.manageEvents,
            subtitle: l10n.manageEventsDescription,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EventManagementScreen(schoolId: schoolId)),
              );
            },
          ),
          const Divider(),
          _buildManagementTile(
            context: context,
            icon: Icons.calendar_today,
            title: l10n.saveSchedule,
            subtitle: l10n.manageSchedulesDescription,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScheduleManagementScreen(schoolId: schoolId),
                ),
              );
            },
          ),
          const Divider(),
          _buildManagementTile(
            context: context,
            icon: Icons.leaderboard,
            title: l10n.manageLevels,
            subtitle: l10n.manageLevelsDescription,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LevelManagementScreen(schoolId: schoolId)),
              );
            },
          ),
          const Divider(),
          _buildManagementTile(
            context: context,
            icon: Icons.menu_book,
            title: l10n.manageTechniques,
            subtitle: l10n.manageTechniquesDescription,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => TechniqueManagementScreen(schoolId: schoolId)),
              );
            },
          ),
          const Divider(),
          _buildManagementTile(
            context: context,
            icon: Icons.price_check,
            title: l10n.manageFinances,
            subtitle: l10n.manageFinancesDescription,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => FinanceManagementScreen(schoolId: schoolId)),
              );
            },
          ),
          const Divider(),
          _buildManagementTile(
            context: context,
            icon: Icons.store,
            title: l10n.editSchoolData,
            subtitle: l10n.editSchoolDataDescription,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EditSchoolDataScreen(schoolId: schoolId)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManagementTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
