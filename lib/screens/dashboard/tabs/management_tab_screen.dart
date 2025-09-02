import 'package:flutter/material.dart';

import '../../schedule/schedule_management_screen.dart';

class ManagementTabScreen extends StatelessWidget {
  final String schoolId;
  const ManagementTabScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de la Escuela'),
      ),
      body: ListView(
        children: [
          _buildManagementTile(
            context: context,
            icon: Icons.calendar_today,
            title: 'Gestionar Horarios',
            subtitle: 'Define los turnos y días de tus clases.',
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
            title: 'Gestionar Niveles',
            subtitle: 'Edita los nombres, colores y orden de las fajas/cinturones.',
            onTap: () {
              // TODO: Navegar a la pantalla de gestión de niveles
            },
          ),
          const Divider(),
          _buildManagementTile(
            context: context,
            icon: Icons.menu_book,
            title: 'Gestionar Técnicas',
            subtitle: 'Añade o modifica el currículo de tu escuela.',
            onTap: () {
              // TODO: Navegar a la pantalla de gestión de técnicas
            },
          ),
          const Divider(),
          _buildManagementTile(
            context: context,
            icon: Icons.price_check,
            title: 'Gestionar Finanzas',
            subtitle: 'Ajusta los precios y planes de pago.',
            onTap: () {
              // TODO: Navegar a la pantalla de gestión de finanzas
            },
          ),
          const Divider(),
          _buildManagementTile(
            context: context,
            icon: Icons.store,
            title: 'Editar Datos de la Escuela',
            subtitle: 'Modifica la dirección, teléfono, descripción, etc.',
            onTap: () {
              // TODO: Navegar a la pantalla de edición de datos
            },
          ),
        ],
      ),
    );
  }

  // Widget de ayuda para construir cada elemento de la lista
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
