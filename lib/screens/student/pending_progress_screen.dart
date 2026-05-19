import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';
import 'package:warrior_path/screens/student/school_search_screen.dart';
import 'package:warrior_path/theme/AppColors.dart';

class PendingProgressScreen extends StatelessWidget {
  final String schoolName;
  final DateTime? applicationDate;

  const PendingProgressScreen({
    super.key,
    required this.schoolName,
    this.applicationDate,
  });

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: const Text('Tu progreso'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              '¡Estás en camino!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu solicitud para "$schoolName" está siendo procesada.',
              style: const TextStyle(fontSize: 15, color: AppColors.textLight),
            ),
            const SizedBox(height: 40),
            _ProgressStepper(
              schoolName: schoolName,
              applicationDate: applicationDate,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Buscar otra escuela'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primaryColor),
                  foregroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SchoolSearchScreen()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStepper extends StatelessWidget {
  final String schoolName;
  final DateTime? applicationDate;

  const _ProgressStepper({required this.schoolName, this.applicationDate});

  @override
  Widget build(BuildContext context) {
    String dateLabel = '';
    if (applicationDate != null) {
      final d = applicationDate!;
      const months = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
      ];
      dateLabel = ' · ${d.day} ${months[d.month - 1]} ${d.year}';
    }

    final steps = [
      _StepData(
        icon: Icons.person_outline,
        title: 'Perfil creado',
        subtitle: 'Tu información ya está registrada',
        status: _StepStatus.done,
      ),
      _StepData(
        icon: Icons.send_outlined,
        title: 'Solicitud enviada',
        subtitle: '"$schoolName"$dateLabel',
        status: _StepStatus.done,
      ),
      _StepData(
        icon: Icons.hourglass_top_outlined,
        title: 'Revisión del maestro',
        subtitle: 'El maestro está evaluando tu postulación',
        status: _StepStatus.current,
      ),
      _StepData(
        icon: Icons.sports_martial_arts_outlined,
        title: 'Listo para entrenar',
        subtitle: 'Tu aventura en el dojo comienza aquí',
        status: _StepStatus.future,
      ),
    ];

    return Column(
      children: steps.indexed
          .map((e) => _StepRow(step: e.$2, isLast: e.$1 == steps.length - 1))
          .toList(),
    );
  }
}

enum _StepStatus { done, current, future }

class _StepData {
  final IconData icon;
  final String title;
  final String subtitle;
  final _StepStatus status;

  const _StepData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
  });
}

class _StepRow extends StatelessWidget {
  final _StepData step;
  final bool isLast;

  const _StepRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final Color iconColor;
    final IconData displayIcon;
    final List<BoxShadow>? shadow;

    switch (step.status) {
      case _StepStatus.done:
        circleColor = Colors.green;
        iconColor = Colors.white;
        displayIcon = Icons.check;
        shadow = null;
      case _StepStatus.current:
        circleColor = AppColors.primaryColor;
        iconColor = Colors.white;
        displayIcon = step.icon;
        shadow = [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ];
      case _StepStatus.future:
        circleColor = Colors.grey.shade300;
        iconColor = Colors.grey.shade400;
        displayIcon = step.icon;
        shadow = null;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                  boxShadow: shadow,
                ),
                child: Icon(displayIcon, color: iconColor, size: 22),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: step.status == _StepStatus.done
                        ? Colors.green.shade200
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: step.status == _StepStatus.future
                          ? AppColors.textLight
                          : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: step.status == _StepStatus.future
                          ? Colors.grey.shade400
                          : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
