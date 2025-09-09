import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/models/payment_plan_model.dart';
import 'package:warrior_path/screens/teacher/techniques/assign_techniques_screen.dart';

import '../../enums/payment_type.dart';
import '../../models/technique_model.dart';

class StudentDetailScreen extends StatefulWidget {
  final String schoolId;
  final String studentId;

  const StudentDetailScreen({
    Key? key,
    required this.schoolId,
    required this.studentId,
  }) : super(key: key);

  @override
  _StudentDetailScreenState createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<QuerySnapshot> _attendanceStream;
  late ConfettiController _confettiController;

  StreamSubscription? _memberSubscription;
  bool _isHeaderLoading = true;
  String _studentName = '';
  String? _photoUrl;
  Map<String, dynamic>? _currentLevelData;
  String _currentRole = 'alumno';
  List<String> _assignedTechniqueIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _listenToMemberData();

    _attendanceStream = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('attendanceRecords').where('presentStudentIds', arrayContains: widget.studentId).orderBy('date', descending: true).snapshots();
  }

  void _listenToMemberData() {
    final memberStream = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).snapshots();
    _memberSubscription = memberStream.listen((memberSnapshot) async {
      if (!memberSnapshot.exists) {
        if (!memberSnapshot.exists) {
          if (mounted) setState(() => _isHeaderLoading = false);
          return;
        }
      }
      final memberData = memberSnapshot.data()!;
      final currentLevelId = memberData['currentLevelId'] ?? memberData['initialLevelId'];
      final results = await Future.wait([_fetchLevelDetails(currentLevelId), _fetchUserPhotoUrl()]);
      if (mounted) {
        setState(() {
          _assignedTechniqueIds = List<String>.from(memberData['assignedTechniqueIds'] ?? []);
          _studentName = memberData['displayName'] ?? 'Alumno';
          _currentRole = memberData['role'] ?? 'alumno';
          _currentLevelData = results[0] as Map<String, dynamic>?;
          _photoUrl = results[1] as String?;
          _isHeaderLoading = false;
        });
      }
    });
  }

  Future<String?> _fetchUserPhotoUrl() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.studentId).get();
    return (userDoc.data() as Map<String, dynamic>?)?['photoUrl'] as String?;
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    _confettiController.dispose();
    _memberSubscription?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchLevelDetails(String? levelId) async {
    if (levelId == null) return null;
    final levelDoc = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('levels').doc(levelId).get();
    if (!levelDoc.exists) return {'name': 'Nivel Borrado', 'colorValue': Colors.grey.value, 'order': -1, 'id': levelId};
    return {...levelDoc.data()!, 'id': levelDoc.id};
  }

  Future<void> _showPromotionDialog(String currentLevelId, int currentLevelOrder) async {
    final levelsSnapshot = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('levels').orderBy('order').get();
    final List<DocumentSnapshot> availableLevels = levelsSnapshot.docs;
    DocumentSnapshot? selectedNextLevel;
    final notesController = TextEditingController();

    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
      return AlertDialog(
        title: const Text('Promover o Corregir Nivel'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<DocumentSnapshot>(
            hint: const Text('Selecciona el nuevo nivel'), value: selectedNextLevel,
            items: availableLevels.map((levelDoc) => DropdownMenuItem<DocumentSnapshot>(value: levelDoc, child: Text(levelDoc['name']))).toList(),
            onChanged: (value) => setDialogState(() => selectedNextLevel = value),
          ),
          const SizedBox(height: 16),
          TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notas (opcional)'), maxLines: 3),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: selectedNextLevel == null ? null : () {
              _promoteStudent(currentLevelId: currentLevelId, newLevelSnapshot: selectedNextLevel!, notes: notesController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Confirmar'),
          ),
        ],
      );
    }));
  }

  Future<void> _promoteStudent({required String currentLevelId, required DocumentSnapshot newLevelSnapshot, required String notes}) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final memberRef = firestore.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId);
      final newLevelId = newLevelSnapshot.id;
      final batch = firestore.batch();
      batch.update(memberRef, {'currentLevelId': newLevelId, 'hasUnseenPromotion': true});
      final historyRef = memberRef.collection('progressionHistory').doc();
      batch.set(historyRef, {'date': Timestamp.now(), 'previousLevelId': currentLevelId, 'newLevelId': newLevelId, 'type': 'level_promotion', 'notes': notes.trim(), 'promotedBy': FirebaseAuth.instance.currentUser?.uid});
      await batch.commit();
      _confettiController.play();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Alumno promovido con éxito!')));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al promover: ${e.toString()}')));
    }
  }

  Future<void> _showChangeRoleDialog(String currentRole) async {
    String? newRole = currentRole;
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
      return AlertDialog(
        title: const Text('Cambiar Rol del Miembro'),
        content: Column(mainAxisSize: MainAxisSize.min, children: ['alumno', 'instructor', 'maestro'].map((role) {
          return RadioListTile<String>(title: Text(role[0].toUpperCase() + role.substring(1)), value: role, groupValue: newRole, onChanged: (value) => setDialogState(() => newRole = value));
        }).toList()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: newRole == null || newRole == currentRole ? null : () {
              _changeStudentRole(newRole!);
              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    }));
  }

  Future<void> _changeStudentRole(String newRole) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final memberRef = firestore.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId);
      batch.update(memberRef, {'role': newRole});
      final userRef = firestore.collection('users').doc(widget.studentId);
      batch.set(userRef, {'activeMemberships': { widget.schoolId: newRole }}, SetOptions(merge: true));
      final historyRef = memberRef.collection('progressionHistory').doc();
      batch.set(historyRef, {'date': Timestamp.now(), 'type': 'role_change', 'newRole': newRole, 'promotedBy': FirebaseAuth.instance.currentUser?.uid});
      await batch.commit();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rol actualizado con éxito.')));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cambiar el rol: ${e.toString()}')));
    }
  }

  Future<void> _showRegisterPaymentDialog() async {
    final firestore = FirebaseFirestore.instance;
    final memberDoc = await firestore.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).get();
    final plansSnapshot = await firestore.collection('schools').doc(widget.schoolId).collection('paymentPlans').get();
    final List<PaymentPlanModel> allPlans = plansSnapshot.docs.map((doc) => PaymentPlanModel.fromFirestore(doc)).toList();
    final assignedPlanId = memberDoc.data()?['paymentPlanId'] as String?;
    final schoolDoc = await firestore.collection('schools').doc(widget.schoolId).get();
    final currency = (schoolDoc.data()?['financials'] as Map<String, dynamic>?)?['currency'] ?? 'USD';

    showDialog(
      context: context,
      builder: (context) {
        return _RegisterPaymentDialog(
          allPlans: allPlans,
          assignedPlanId: assignedPlanId,
          currency: currency,
          onSave: (String concept, double amount, String? planId) {
            _savePayment(concept: concept, amount: amount, currency: currency, planId: planId);
          },
        );
      },
    );
  }

  Future<void> _savePayment({
    required String concept,
    required double amount,
    required String currency,
    String? planId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('schools').doc(widget.schoolId)
          .collection('members').doc(widget.studentId)
          .collection('payments').add({
        'paymentDate': Timestamp.now(),
        'concept': concept.trim(),
        'amount': amount,
        'currency': currency,
        'recordedBy': FirebaseAuth.instance.currentUser?.uid,
        'schoolId': widget.schoolId,
        'paymentPlanId': planId,
        'studentId': widget.studentId,
        'studentName': _studentName,
      });

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago registrado con éxito.')));

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al registrar el pago: ${e.toString()}')));
    }
  }

  Future<void> _showAssignPlanDialog(String? currentPlanId) async {
    final firestore = FirebaseFirestore.instance;

    // 1. Obtener todos los planes disponibles en la escuela
    final plansSnapshot = await firestore
        .collection('schools').doc(widget.schoolId)
        .collection('paymentPlans').get();

    final List<PaymentPlanModel> allPlans = plansSnapshot.docs
        .map((doc) => PaymentPlanModel.fromFirestore(doc)).toList();

    // 2. Encontrar el plan seleccionado actualmente (si existe)
    PaymentPlanModel? selectedPlan;
    if (currentPlanId != null && allPlans.any((p) => p.id == currentPlanId)) {
      selectedPlan = allPlans.firstWhere((p) => p.id == currentPlanId);
    }

    // 3. Mostrar el diálogo
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // StatefulBuilder para actualizar el Dropdown
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Asignar Plan de Pago'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<PaymentPlanModel>(
                  value: selectedPlan,
                  hint: const Text('Selecciona un plan'),
                  items: allPlans.map((plan) {
                    return DropdownMenuItem(
                      value: plan,
                      child: Text('${plan.title} (${plan.amount} ${plan.currency})'),
                    );
                  }).toList(),
                  onChanged: (plan) {
                    setDialogState(() => selectedPlan = plan);
                  },
                ),
                const SizedBox(height: 16),
                // Opción para quitar el plan
                TextButton(
                  child: const Text('Quitar plan asignado', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    // Actualiza Firestore poniendo el campo en null
                    firestore
                        .collection('schools').doc(widget.schoolId)
                        .collection('members').doc(widget.studentId)
                        .update({'assignedPaymentPlanId': null}); // <-- Aquí usamos el nuevo campo
                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                // Solo se activa si seleccionaron un plan
                onPressed: selectedPlan == null
                    ? null
                    : () {
                  // Aquí actualizamos el documento del MIEMBRO con el NUEVO CAMPO
                  firestore
                      .collection('schools').doc(widget.schoolId)
                      .collection('members').doc(widget.studentId)
                      .update({'assignedPaymentPlanId': selectedPlan!.id}); // <-- Aquí usamos el nuevo campo
                  Navigator.of(context).pop();
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(_studentName.isEmpty ? 'Cargando...' : _studentName),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) { if (value == 'change_role') _showChangeRoleDialog(_currentRole); },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(value: 'change_role', child: Text('Cambiar Rol')),
                ],
              ),
            ],
          ),
          body: _isHeaderLoading ? const Center(child: CircularProgressIndicator()) : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty) ? NetworkImage(_photoUrl!) : null,
                    child: (_photoUrl == null || _photoUrl!.isEmpty) ? const Icon(Icons.person, size: 40) : null,
                  ),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_studentName, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(_currentRole.toUpperCase(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_currentLevelData?['name'] ?? 'Sin Nivel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: _currentLevelData != null ? Color(_currentLevelData!['colorValue']) : Colors.grey,
                    ),
                  ]),
                ]),
              ),
              TabBar(controller: _tabController, isScrollable: true, tabs: const [
                Tab(text: 'General'),
                Tab(text: 'Asistencia'),
                Tab(text: 'Pagos'),
                Tab(text: 'Progreso'),
                Tab(text: 'Técnicas'),
              ]),
              Expanded(
                child: TabBarView(controller: _tabController, children: [
                  _buildGeneralInfoTab(),
                  _buildAttendanceHistoryTab(),
                  _buildPaymentsHistoryTab(),
                  _buildProgressionHistoryTab(),
                  _buildAssignedTechniquesTab(),
                ]),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false, numberOfParticles: 30, emissionFrequency: 0.05, maxBlastForce: 20, minBlastForce: 8, gravity: 0.3,
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
        ),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: _showAddPastAttendanceDialog,
          label: const Text('Registrar Asistencia Pasada'),
          icon: const Icon(Icons.playlist_add_check),
        );
      case 2: return FloatingActionButton.extended(onPressed: _showRegisterPaymentDialog, label: const Text('Registrar Pago'), icon: const Icon(Icons.payment));
      case 3: return FloatingActionButton.extended(
        onPressed: () {
          if (_currentLevelData != null) {
            _showPromotionDialog(_currentLevelData!['id'], _currentLevelData!['order']);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo cargar el nivel actual del alumno.')));
          }
        },
        label: const Text('Promover Nivel'),
        icon: const Icon(Icons.arrow_upward),
      );
      case 4:
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AssignTechniquesScreen(
                schoolId: widget.schoolId,
                studentId: widget.studentId,
                alreadyAssignedIds: _assignedTechniqueIds,
              ),
            ));
          },
          label: const Text('Asignar Técnicas'),
          icon: const Icon(Icons.add_task),
        );
      default: return null;
    }
  }

  Widget _buildAssignedTechniquesTab() {
    if (_assignedTechniqueIds.isEmpty) {
      return const Center(child: Text('Este alumno no tiene técnicas asignadas.'));
    }
    // Hacemos una consulta para obtener los detalles de las técnicas asignadas
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools').doc(widget.schoolId)
          .collection('techniques')
          .where(FieldPath.documentId, whereIn: _assignedTechniqueIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final techniques = snapshot.data!.docs;

        return ListView.builder(
          itemCount: techniques.length,
          itemBuilder: (context, index) {
            final tech = TechniqueModel.fromFirestore(techniques[index]);
            return ListTile(
              title: Text(tech.name),
              subtitle: Text(tech.category),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () async {
                  // Lógica para eliminar la asignación
                  await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).update({
                    'assignedTechniqueIds': FieldValue.arrayRemove([tech.id])
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGeneralInfoTab() {
    return StreamBuilder<DocumentSnapshot>(
      // ATENCIÓN: Ahora usamos un STREAM en lugar de un FUTUREBUILDER.
      // Necesitamos un Stream para que el plan asignado se actualice en vivo
      // cuando el maestro lo cambie usando el diálogo.
      stream: FirebaseFirestore.instance
          .collection('schools').doc(widget.schoolId)
          .collection('members').doc(widget.studentId)
          .snapshots(),
      builder: (context, memberSnapshot) {
        if (!memberSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        // Obtenemos los datos del miembro (alumno)
        final memberData = memberSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final String? assignedPlanId = memberData['assignedPaymentPlanId'] as String?; // <-- Leemos el nuevo campo

        return FutureBuilder<DocumentSnapshot>(
          // Usamos un FutureBuilder anidado solo para los datos del usuario (Email/Teléfono)
          // ya que estos no cambian, pero los datos del Miembro (el plan) sí.
          future: FirebaseFirestore.instance.collection('users').doc(widget.studentId).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                // --- INICIO DE LA NUEVA TARJETA DE FACTURACIÓN ---
                _buildInfoCard(
                  title: 'Facturación',
                  icon: Icons.receipt_long,
                  iconColor: Colors.blueAccent,
                  // El contenido de la tarjeta es otro FutureBuilder que busca
                  // los detalles del plan asignado.
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      // Buscamos los detalles del plan solo si el ID existe
                      future: assignedPlanId == null
                          ? null // Si no hay ID, el future es nulo
                          : FirebaseFirestore.instance
                          .collection('schools').doc(widget.schoolId)
                          .collection('paymentPlans').doc(assignedPlanId)
                          .get(),
                      builder: (context, planSnapshot) {
                        String planDetailsText = 'Sin plan de pago asignado.';

                        if (planSnapshot.connectionState == ConnectionState.waiting) {
                          planDetailsText = 'Cargando plan...';
                        } else if (planSnapshot.hasData && planSnapshot.data!.exists) {
                          // Si encontramos el plan, creamos un modelo
                          final plan = PaymentPlanModel.fromFirestore(planSnapshot.data!);
                          planDetailsText = '${plan.title} (${plan.amount} ${plan.currency})';
                        } else if (assignedPlanId != null) {
                          planDetailsText = 'Plan asignado (ID: $assignedPlanId) no encontrado.';
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(planDetailsText, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton(
                                child: const Text('Cambiar Plan Asignado'),
                                onPressed: () => _showAssignPlanDialog(assignedPlanId),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  ],
                ),
                // --- FIN DE LA NUEVA TARJETA DE FACTURACIÓN ---

                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Datos de Contacto',
                  icon: Icons.contact_page,
                  children: [
                    _buildInfoRow('Email:', userData['email'] ?? 'No especificado'),
                    _buildInfoRow('Teléfono:', userData['phoneNumber'] ?? 'No especificado'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Información de Emergencia',
                  icon: Icons.emergency,
                  iconColor: Colors.red,
                  children: [
                    _buildInfoRow('Contacto:', userData['emergencyContactName'] ?? 'No especificado'),
                    _buildInfoRow('Teléfono:', userData['emergencyContactPhone'] ?? 'No especificado'),
                    _buildInfoRow('Servicio Médico:', userData['medicalEmergencyService'] ?? 'No especificado'),
                    const Divider(),
                    _buildInfoRow('Info Médica:', userData['medicalInfo'] ?? 'Sin observaciones'),
                  ],
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, Color? iconColor, required List<Widget> children}) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Esta es la fila que da el error
                  Row(
                    children: [
                      Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2
                        ),
                      ),
                    ],
                  ),
      const Divider(height: 20), ...children,
    ])));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8),
      Expanded(child: Text(value.isEmpty ? 'No especificado' : value)),
    ]));
  }

  Widget _buildPaymentsHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).collection('payments').orderBy('paymentDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No hay pagos registrados para este alumno.'));
        return ListView.builder(itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
          final payment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
          final date = (payment['paymentDate'] as Timestamp).toDate();
          final formattedDate = DateFormat('dd/MM/yyyy').format(date);
          return ListTile(leading: const Icon(Icons.receipt_long, color: Colors.green), title: Text(payment['concept'] ?? 'Pago'), subtitle: Text(formattedDate), trailing: Text('${payment['amount']} ${payment['currency']}', style: const TextStyle(fontWeight: FontWeight.bold)));
        });
      },
    );
  }

  Widget _buildAttendanceHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _attendanceStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return const Center(child: Text('Error al cargar el historial.'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay registros de asistencia para este alumno.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index]; // Obtenemos el documento completo
            final record = doc.data() as Map<String, dynamic>;
            final date = (record['date'] as Timestamp).toDate();
            final formattedDate = DateFormat('dd/MM/yyyy', 'es_ES').format(date);

            return ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(record['scheduleTitle'] ?? 'Clase'),
              subtitle: Text(formattedDate),

              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Quitar esta asistencia',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmar'),
                      content: const Text('¿Estás seguro de que quieres eliminar esta asistencia del registro del alumno?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
                      ],
                    ),
                  );

                  if (confirm ?? false) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('schools').doc(widget.schoolId)
                          .collection('attendanceRecords').doc(doc.id)
                          .update({
                        'presentStudentIds': FieldValue.arrayRemove([widget.studentId])
                      });

                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asistencia eliminada.')));

                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressionHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).collection('progressionHistory').orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) { print('ERROR DEL STREAM DE PROGRESO: ${snapshot.error}'); return const Center(child: Text('Error al cargar el progreso.')); }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Este alumno no tiene historial de promociones.'));
        return ListView.builder(itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
          final history = snapshot.data!.docs[index].data() as Map<String, dynamic>;
          final eventType = history['type'] ?? 'level_promotion';
          if (eventType == 'role_change') return _buildRoleChangeEventTile(history);
          return _buildLevelPromotionEventTile(history);
        });
      },
    );
  }

  Widget _buildRoleChangeEventTile(Map<String, dynamic> history) {
    final date = (history['date'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final newRole = history['newRole'] ?? '';
    final roleText = 'Rol actualizado a ${newRole[0].toUpperCase()}${newRole.substring(1)}';
    return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: ListTile(leading: const Icon(Icons.admin_panel_settings), title: Text(roleText), trailing: Text(formattedDate)));
  }

  Widget _buildLevelPromotionEventTile(Map<String, dynamic> history) {
    final date = (history['date'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final notes = history['notes'] as String?;
    final levelId = history['newLevelId'];
    if (levelId == null) return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: ListTile(leading: const Icon(Icons.error, color: Colors.red), title: const Text('Registro de promoción inválido'), trailing: Text(formattedDate)));
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('levels').doc(levelId).get(),
      builder: (context, levelSnapshot) {
        String levelName = 'Cargando...';
        Color levelColor = Colors.grey;
        if (levelSnapshot.connectionState == ConnectionState.done) {
          if (levelSnapshot.hasData && levelSnapshot.data!.exists) {
            final levelData = levelSnapshot.data!.data() as Map<String, dynamic>;
            levelName = levelData['name'] ?? 'Nivel Borrado';
            levelColor = Color(levelData['colorValue']);
          } else {
            levelName = 'Nivel Borrado';
            levelColor = Colors.grey.shade400;
          }
        }
        return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: ListTile(leading: Icon(Icons.military_tech, color: levelColor), title: Text('Promovido a $levelName'), subtitle: (notes != null && notes.isNotEmpty) ? Text('Notas: "$notes"') : null, trailing: Text(formattedDate)));
      },
    );
  }

  // --- PEGA ESTAS DOS NUEVAS FUNCIONES DENTRO DE _StudentDetailScreenState ---

  /// Muestra el selector de calendario para elegir una fecha pasada.
  Future<void> _showAddPastAttendanceDialog() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020), // Desde qué año permites registrar
      lastDate: DateTime.now(), // No puedes registrar asistencias futuras
      locale: const Locale('es', 'ES'), // Asegúrate de tener intl configurado para español
    );

    if (pickedDate == null) return; // El usuario canceló

    // Una vez que tenemos la fecha, necesitamos saber qué clases hubo ese día.
    // Usamos 'pickedDate.weekday' (Lunes=1, Domingo=7, igual que tu app)
    final int dayOfWeek = pickedDate.weekday;

    final schedulesSnap = await FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('classSchedules')
        .where('dayOfWeek', isEqualTo: dayOfWeek)
        .get();

    if (schedulesSnap.docs.isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No había clases programadas para el día seleccionado.')));
      return;
    }

    // Si encontramos clases, mostramos el diálogo para seleccionar cuál.
    // (Este es el mismo diálogo que usas en tu HomeTabScreen)
    if (mounted) {
      _selectScheduleForDate(schedulesSnap.docs, pickedDate);
    }
  }

  /// Muestra la lista de clases disponibles para una fecha específica.
  void _selectScheduleForDate(List<QueryDocumentSnapshot> schedules, DateTime selectedDate) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Clases del ${DateFormat.yMd('es_ES').format(selectedDate)}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index].data() as Map<String, dynamic>;
                final scheduleTitle = schedule['title'];
                final scheduleTime = '${schedule['startTime']} - ${schedule['endTime']}';

                return ListTile(
                  title: Text(scheduleTitle),
                  subtitle: Text(scheduleTime),
                  onTap: () {
                    _savePastAttendance(scheduleTitle, selectedDate);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Guarda la asistencia (Paso final)
  Future<void> _savePastAttendance(String scheduleTitle, DateTime date) async {
    // Para guardar la asistencia, replicamos la lógica de tu 'AttendanceChecklistScreen'.
    // Necesitamos encontrar (o crear) el documento 'attendanceRecord' para ESA fecha y ESE horario.
    // Asumimos que la ID del documento es una combinación de la fecha y el título,
    // o que se busca por esos campos.

    // La forma más robusta (usada por AttendanceChecklistScreen) suele ser buscar
    // un registro que coincida con la fecha (sin hora) Y el título.
    final normalizedDate = Timestamp.fromDate(DateTime(date.year, date.month, date.day));

    final firestore = FirebaseFirestore.instance;
    final recordsRef = firestore.collection('schools').doc(widget.schoolId).collection('attendanceRecords');

    try {
      final query = await recordsRef
          .where('date', isEqualTo: normalizedDate)
          .where('scheduleTitle', isEqualTo: scheduleTitle)
          .limit(1)
          .get();

      String attendanceDocId;

      if (query.docs.isEmpty) {
        // No existe un registro para esa clase/fecha. Lo creamos.
        final newDocRef = await recordsRef.add({
          'date': normalizedDate,
          'scheduleTitle': scheduleTitle,
          'schoolId': widget.schoolId,
          'presentStudentIds': [widget.studentId], // Creamos la lista CON el alumno
          'recordedBy': FirebaseAuth.instance.currentUser?.uid,
        });
        attendanceDocId = newDocRef.id;
      } else {
        // El registro ya existe. Simplemente añadimos al alumno al array.
        attendanceDocId = query.docs.first.id;
        await recordsRef.doc(attendanceDocId).update({
          'presentStudentIds': FieldValue.arrayUnion([widget.studentId]) // arrayUnion evita duplicados
        });
      }

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asistencia registrada con éxito.')));

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }
}

class _RegisterPaymentDialog extends StatefulWidget {
  final List<PaymentPlanModel> allPlans;
  final String? assignedPlanId;
  final String currency;
  final Function(String, double, String?) onSave;

  const _RegisterPaymentDialog({
    required this.allPlans, this.assignedPlanId, required this.currency, required this.onSave,
  });

  @override
  State<_RegisterPaymentDialog> createState() => _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState extends State<_RegisterPaymentDialog> {
  PaymentType _paymentType = PaymentType.plan;
  PaymentPlanModel? _selectedPlan;
  final _conceptController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentType = PaymentType.plan;
    if (widget.assignedPlanId != null && widget.allPlans.any((p) => p.id == widget.assignedPlanId)) {
      _selectedPlan = widget.allPlans.firstWhere((p) => p.id == widget.assignedPlanId);
    }
    _updateFieldsFromPlan();
  }

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateFieldsFromPlan() {
    if (_selectedPlan != null) {
      _conceptController.text = _selectedPlan!.title;
      _amountController.text = _selectedPlan!.amount.toString();
    } else {
      _conceptController.text = '';
      _amountController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Pago'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ToggleButtons(
            isSelected: [_paymentType == PaymentType.plan, _paymentType == PaymentType.special],
            onPressed: (index) {
              setState(() {
                _paymentType = index == 0 ? PaymentType.plan : PaymentType.special;
                if (_paymentType == PaymentType.plan) {
                  _updateFieldsFromPlan();
                } else {
                  _conceptController.text = ''; _amountController.text = '';
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Pago de Plan')), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Pago Especial'))],
          ),
          const SizedBox(height: 24),
          if (_paymentType == PaymentType.plan)
            DropdownButtonFormField<PaymentPlanModel>(
              value: _selectedPlan,
              hint: const Text('Selecciona un plan'),
              items: widget.allPlans.map((plan) => DropdownMenuItem(value: plan, child: Text(plan.title))).toList(),
              onChanged: (plan) { setState(() { _selectedPlan = plan; _updateFieldsFromPlan(); }); },
            ),
          const SizedBox(height: 16),
          TextField(controller: _conceptController, decoration: const InputDecoration(labelText: 'Concepto'), enabled: _paymentType == PaymentType.special),
          const SizedBox(height: 16),
          TextField(controller: _amountController, decoration: InputDecoration(labelText: 'Monto', prefixText: '${widget.currency} '), keyboardType: const TextInputType.numberWithOptions(decimal: true), enabled: _paymentType == PaymentType.special),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_conceptController.text, double.tryParse(_amountController.text) ?? 0.0, _paymentType == PaymentType.plan ? _selectedPlan?.id : null);
            Navigator.of(context).pop();
          },
          child: const Text('Guardar Pago'),
        ),
      ],
    );
  }
}
