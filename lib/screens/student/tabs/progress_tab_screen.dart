import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProgressTabScreen extends StatefulWidget {
  final String schoolId;
  final String memberId;

  const ProgressTabScreen({
    Key? key,
    required this.schoolId,
    required this.memberId,
  }) : super(key: key);

  @override
  State<ProgressTabScreen> createState() => _ProgressTabScreenState();
}

class _ProgressTabScreenState extends State<ProgressTabScreen> {
  // Future para cargar el nivel actual del alumno y todos los niveles de la escuela
  late Future<Map<String, dynamic>> _progressDataFuture;

  @override
  void initState() {
    super.initState();
    _progressDataFuture = _fetchProgressData();
  }

  Future<Map<String, dynamic>> _fetchProgressData() async {
    final firestore = FirebaseFirestore.instance;

    // 1. Obtener el documento del miembro para saber su nivel actual
    final memberDoc = await firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('members')
        .doc(widget.memberId)
        .get();

    final currentLevelId = memberDoc.data()?['currentLevelId'];

    // 2. Obtener los detalles de ese nivel actual
    DocumentSnapshot? currentLevelDoc;
    if (currentLevelId != null) {
      currentLevelDoc = await firestore
          .collection('schools')
          .doc(widget.schoolId)
          .collection('levels')
          .doc(currentLevelId)
          .get();
    }

    // 3. Obtener TODOS los niveles de la escuela, ordenados
    final allLevelsQuery = await firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('levels')
        .orderBy('order')
        .get();

    return {
      'currentLevel': currentLevelDoc,
      'allLevels': allLevelsQuery.docs,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Progreso')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _progressDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('No se pudo cargar tu progreso.'));
          }

          final currentLevelDoc = snapshot.data!['currentLevel'] as DocumentSnapshot?;
          final allLevels = snapshot.data!['allLevels'] as List<QueryDocumentSnapshot>;

          return SingleChildScrollView(
            child: Column(
              children: [
                // --- CABECERA DE NIVEL ACTUAL ---
                _buildCurrentLevelHeader(currentLevelDoc),

                const Divider(height: 32),

                // --- CAMINO DE PROGRESIÓN ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Tu Camino', style: Theme.of(context).textTheme.headlineSmall),
                ),
                const SizedBox(height: 8),
                _buildProgressionPath(currentLevelDoc, allLevels),

                // Aquí irían otras secciones como Historial de Exámenes, etc.
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentLevelHeader(DocumentSnapshot? currentLevelDoc) {
    if (currentLevelDoc == null || !currentLevelDoc.exists) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Text('Aún no tienes un nivel asignado.'),
      );
    }

    final data = currentLevelDoc.data() as Map<String, dynamic>;
    final levelName = data['name'] ?? 'Nivel Desconocido';
    final levelColor = Color(data['colorValue']);

    return Container(
      width: double.infinity,
      color: levelColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Text('Tu Nivel Actual', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: levelColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3)),
              ],
            ),
            child: Text(
              levelName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionPath(DocumentSnapshot? currentLevelDoc, List<QueryDocumentSnapshot> allLevels) {
    if (allLevels.isEmpty) {
      return const Text('El sistema de progresión no ha sido definido.');
    }

    final currentLevelOrder = (currentLevelDoc?.data() as Map<String, dynamic>?)?['order'] ?? -1;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allLevels.length,
      itemBuilder: (context, index) {
        final level = allLevels[index].data() as Map<String, dynamic>;
        final levelOrder = level['order'] as int;
        final isCompleted = levelOrder < currentLevelOrder;
        final isCurrent = levelOrder == currentLevelOrder;

        return ListTile(
          leading: isCompleted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : isCurrent
              ? Icon(Icons.star, color: Theme.of(context).primaryColor)
              : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
          title: Text(level['name']),
          tileColor: isCurrent ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        );
      },
    );
  }
}
