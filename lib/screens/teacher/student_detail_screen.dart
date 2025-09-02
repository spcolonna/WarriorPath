import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  // Variables de estado para la cabecera para evitar parpadeos
  StreamSubscription? _memberSubscription;
  bool _isHeaderLoading = true;
  String _studentName = '';
  String? _photoUrl;
  Map<String, dynamic>? _currentLevelData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _listenToMemberData(); // Empezamos a escuchar los datos del miembro

    // El stream de asistencia se define una vez
    _attendanceStream = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('attendanceRecords').where('presentStudentIds', arrayContains: widget.studentId).orderBy('date', descending: true).snapshots();
  }

  void _listenToMemberData() {
    final memberStream = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).snapshots();

    _memberSubscription = memberStream.listen((memberSnapshot) async {
      if (!memberSnapshot.exists) {
        if (mounted) setState(() => _isHeaderLoading = false);
        return;
      }

      final memberData = memberSnapshot.data()!;
      final currentLevelId = memberData['currentLevelId'] ?? memberData['initialLevelId'];

      final results = await Future.wait([
        _fetchLevelDetails(currentLevelId),
        _fetchUserPhotoUrl(),
      ]);

      final levelData = results[0] as Map<String, dynamic>?;
      final photoUrl = results[1] as String?;

      if (mounted) {
        setState(() {
          _studentName = memberData['displayName'] ?? 'Alumno';
          _currentLevelData = levelData;
          _photoUrl = photoUrl;
          _isHeaderLoading = false;
        });
      }
    });
  }

  Future<String?> _fetchUserPhotoUrl() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.studentId).get();
    return (userDoc.data() as Map<String, dynamic>)['photoUrl'] as String?;
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    _confettiController.dispose();
    _memberSubscription?.cancel(); // Se cancela la suscripción al stream
    super.dispose();
  }

  Future<void> _showRegisterPaymentDialog() async {
    final schoolDoc = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).get();
    final financials = schoolDoc.data()?['financials'] as Map<String, dynamic>? ?? {};
    final defaultAmount = financials['monthlyFee']?.toString() ?? '0.0';
    final currency = financials['currency'] ?? 'USD';
    final amountController = TextEditingController(text: defaultAmount);
    final conceptController = TextEditingController(text: 'Cuota Mensual - ${DateFormat('MMMM yyyy', 'es_ES').format(DateTime.now())}');

    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Registrar Nuevo Pago'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: conceptController, decoration: const InputDecoration(labelText: 'Concepto')),
        const SizedBox(height: 16),
        TextField(controller: amountController, decoration: InputDecoration(labelText: 'Monto', prefixText: '$currency '), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            _savePayment(concept: conceptController.text, amount: double.tryParse(amountController.text) ?? 0.0, currency: currency);
            Navigator.of(context).pop();
          },
          child: const Text('Guardar Pago'),
        ),
      ],
    ));
  }

  Future<void> _savePayment({required String concept, required double amount, required String currency}) async {
    try {
      await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).collection('payments').add({
        'paymentDate': Timestamp.now(), 'concept': concept.trim(), 'amount': amount, 'currency': currency, 'recordedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago registrado con éxito.')));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al registrar el pago: ${e.toString()}')));
    }
  }

  Future<Map<String, dynamic>?> _fetchLevelDetails(String? levelId) async {
    if (levelId == null) return null;
    final levelDoc = await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('levels').doc(levelId).get();
    if (!levelDoc.exists) return {'name': 'Nivel no encontrado', 'colorValue': Colors.red.value, 'order': -1, 'id': levelId};
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
            hint: const Text('Selecciona el nuevo nivel'),
            value: selectedNextLevel,
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
      batch.set(historyRef, {'date': Timestamp.now(), 'previousLevelId': currentLevelId, 'newLevelId': newLevelId, 'notes': notes.trim(), 'promotedBy': FirebaseAuth.instance.currentUser?.uid});
      await batch.commit();

      _confettiController.play();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Alumno promovido con éxito!')));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al promover: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(_studentName.isEmpty ? 'Cargando...' : _studentName),
          ),
          body: _isHeaderLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty) ? NetworkImage(_photoUrl!) : null,
                      child: (_photoUrl == null || _photoUrl!.isEmpty) ? const Icon(Icons.person, size: 40) : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_studentName, style: Theme.of(context).textTheme.headlineSmall),
                        Chip(
                          label: Text(
                            _currentLevelData?['name'] ?? 'Sin Nivel',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _currentLevelData != null ? Color(_currentLevelData!['colorValue']) : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'General'),
                  Tab(text: 'Asistencia'),
                  Tab(text: 'Pagos'),
                  Tab(text: 'Progreso'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGeneralInfoTab(),
                    _buildAttendanceHistoryTab(),
                    _buildPaymentsHistoryTab(),
                    const Center(child: Text('Historial de Exámenes y Promociones')),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 30,
          emissionFrequency: 0.05,
          maxBlastForce: 20,
          minBlastForce: 8,
          gravity: 0.3,
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
        ),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 2: // Pagos
        return FloatingActionButton.extended(onPressed: _showRegisterPaymentDialog, label: const Text('Registrar Pago'), icon: const Icon(Icons.payment));
      case 3: // Progreso
        return FloatingActionButton.extended(
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
      default: return null;
    }
  }

  Widget _buildGeneralInfoTab() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(widget.studentId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('No se encontró el perfil del usuario.'));
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            _buildInfoCard(title: 'Datos de Contacto', icon: Icons.contact_page, children: [
              _buildInfoRow('Email:', userData['email'] ?? 'No especificado'),
              _buildInfoRow('Teléfono:', userData['phoneNumber'] ?? 'No especificado'),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard(title: 'Información de Emergencia', icon: Icons.emergency, iconColor: Colors.red, children: [
              _buildInfoRow('Contacto:', userData['emergencyContactName'] ?? 'No especificado'),
              _buildInfoRow('Teléfono:', userData['emergencyContactPhone'] ?? 'No especificado'),
              _buildInfoRow('Servicio Médico:', userData['medicalEmergencyService'] ?? 'No especificado'),
              const Divider(),
              _buildInfoRow('Info Médica:', userData['medicalInfo'] ?? 'Sin observaciones'),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, Color? iconColor, required List<Widget> children}) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ]),
        const Divider(height: 20),
        ...children,
      ])),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(width: 8),
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
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          print('ERROR DEL STREAM DE ASISTENCIA: ${snapshot.error}');
          return const Center(child: Text('Error al cargar el historial.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No hay registros de asistencia para este alumno.'));
        return ListView.builder(itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
          final record = snapshot.data!.docs[index].data() as Map<String, dynamic>;
          final date = (record['date'] as Timestamp).toDate();
          final formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
          return ListTile(leading: const Icon(Icons.check_circle, color: Colors.green), title: Text(record['scheduleTitle'] ?? 'Clase'), trailing: Text(formattedDate));
        });
      },
    );
  }
}
