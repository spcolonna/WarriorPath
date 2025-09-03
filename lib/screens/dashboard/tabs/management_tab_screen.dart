import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warrior_path/providers/session_provider.dart';
import 'package:warrior_path/screens/schedule/schedule_management_screen.dart';

class ManagementTabScreen extends StatelessWidget {
  // 1. EL CONSTRUCTOR YA NO NECESITA schoolId
  const ManagementTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 2. OBTENEMOS EL schoolId DESDE EL PROVIDER
    final schoolId = Provider.of<SessionProvider>(context).activeSchoolId;

    // Fallback por si no hay sesión activa
    if (schoolId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de la Escuela')),
        body: const Center(child: Text('Error: No hay una escuela activa en la sesión.')),
      );
    }

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
                  // 3. USAMOS EL schoolId OBTENIDO DEL PROVIDER
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

  // Este widget de ayuda no necesita cambios
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
