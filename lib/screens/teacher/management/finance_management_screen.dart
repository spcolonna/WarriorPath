import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/models/payment_plan_model.dart';

class FinanceManagementScreen extends StatefulWidget {
  final String schoolId;
  const FinanceManagementScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<FinanceManagementScreen> createState() => _FinanceManagementScreenState();
}

class _FinanceManagementScreenState extends State<FinanceManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controladores para los costos únicos
  final _inscriptionFeeController = TextEditingController();
  final _examFeeController = TextEditingController();
  String _selectedCurrency = 'USD';
  final List<String> _currencies = ['USD', 'UYU', 'ARS', 'EUR', 'MXN'];

  // Listas para los planes
  List<PaymentPlanModel> _plans = [];
  List<PaymentPlanModel> _initialPlans = [];

  late Future<Map<String, dynamic>> _reportDataFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFinancialData();
    _reportDataFuture = _fetchAndProcessReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inscriptionFeeController.dispose();
    _examFeeController.dispose();
    super.dispose();
  }

  Future<void> _fetchFinancialData() async {
    setState(() => _isLoading = true);
    try {
      final schoolDocFuture = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).get();
      final plansSnapshotFuture = FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('paymentPlans').get();

      final results = await Future.wait([schoolDocFuture, plansSnapshotFuture]);

      final schoolDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final plansSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;

      if (schoolDoc.exists) {
        final financials = schoolDoc.data()?['financials'] as Map<String, dynamic>? ?? {};
        _inscriptionFeeController.text = financials['inscriptionFee']?.toString() ?? '0';
        _examFeeController.text = financials['examFee']?.toString() ?? '0';
        _selectedCurrency = financials['currency'] ?? 'USD';
      }

      _plans = plansSnapshot.docs.map((doc) => PaymentPlanModel.fromFirestore(doc)).toList();
      _initialPlans = _plans.map((plan) => PaymentPlanModel.fromModel(plan)).toList();

    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar datos: ${e.toString()}')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _showPlanDialog({PaymentPlanModel? plan}) {
    final bool isEditing = plan != null;
    final model = isEditing ? PaymentPlanModel.fromModel(plan) : PaymentPlanModel(title: '', amount: 0.0, currency: _selectedCurrency);

    final titleController = TextEditingController(text: model.title);
    final amountController = TextEditingController(text: isEditing && model.amount > 0 ? model.amount.toString() : '');
    final descriptionController = TextEditingController(text: model.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Plan' : 'Nuevo Plan de Pago'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título del Plan*')),
            const SizedBox(height: 16),
            TextField(controller: amountController, decoration: InputDecoration(labelText: 'Monto*', hintText: '0.0', prefixText: '$_selectedCurrency '), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 2),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                model.title = titleController.text;
                model.amount = double.tryParse(amountController.text) ?? 0.0;
                model.description = descriptionController.text;
                model.currency = _selectedCurrency;

                if (isEditing) {
                  final index = _plans.indexWhere((p) => p.id == model.id);
                  if (index != -1) _plans[index] = model;
                } else {
                  _plans.add(model);
                }
              });
              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final schoolRef = firestore.collection('schools').doc(widget.schoolId);
      final plansRef = schoolRef.collection('paymentPlans');
      final batch = firestore.batch();

      final financialData = {
        'inscriptionFee': double.tryParse(_inscriptionFeeController.text) ?? 0.0,
        'examFee': double.tryParse(_examFeeController.text) ?? 0.0,
        'currency': _selectedCurrency,
      };
      batch.update(schoolRef, {'financials': financialData});

      final initialIds = _initialPlans.map((p) => p.id).toSet();
      final currentIds = _plans.map((p) => p.id).toSet();
      final deletedIds = initialIds.difference(currentIds);

      for (final id in deletedIds) {
        if (id != null) batch.delete(plansRef.doc(id));
      }

      for (final plan in _plans) {
        if (plan.id == null) {
          batch.set(plansRef.doc(), plan.toJson());
        } else {
          batch.update(plansRef.doc(plan.id), plan.toJson());
        }
      }

      await batch.commit();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Finanzas actualizadas con éxito.'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${e.toString()}')));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  Future<Map<String, dynamic>> _fetchAndProcessReportData() async {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);

    // Usamos una 'Collection Group Query' para buscar en todos los sub-colecciones de 'payments'
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('payments')
        .where('schoolId', isEqualTo: widget.schoolId)
        .orderBy('paymentDate', descending: true)
        .get();

    double currentMonthTotal = 0;
    Map<int, double> monthlyTotals = {}; // Mapa para [mes: total]

    for (var doc in snapshot.docs) {
      final payment = doc.data();
      final date = (payment['paymentDate'] as Timestamp).toDate();
      final amount = (payment['amount'] as num).toDouble();

      // Sumar al total del mes actual
      if (date.isAfter(currentMonthStart)) {
        currentMonthTotal += amount;
      }

      // Agrupar por mes para la gráfica
      final monthKey = date.year * 100 + date.month;
      monthlyTotals.update(monthKey, (value) => value + amount, ifAbsent: () => amount);
    }

    return {
      'currentMonthTotal': currentMonthTotal,
      'monthlyTotals': monthlyTotals,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Finanzas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [ Tab(text: 'Planes y Precios'), Tab(text: 'Reportes') ],
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : AbsorbPointer(
        absorbing: _isSaving,
        child: TabBarView(
          controller: _tabController,
          children: [
            Scaffold( // Scaffold interno para la primera pestaña
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 160), // Padding inferior para que no se tapen los botones
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Costos Únicos', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(value: _selectedCurrency, decoration: const InputDecoration(labelText: 'Moneda', border: OutlineInputBorder()), items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) { if (v != null) setState(() => _selectedCurrency = v); }),
                    const SizedBox(height: 16),
                    TextFormField(controller: _inscriptionFeeController, decoration: InputDecoration(labelText: 'Precio de Inscripción', prefixText: '$_selectedCurrency ', border: const OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]),
                    const SizedBox(height: 16),
                    TextFormField(controller: _examFeeController, decoration: InputDecoration(labelText: 'Precio por Examen', prefixText: '$_selectedCurrency ', border: const OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]),
                    const Divider(height: 40),
                    Text('Planes de Cuotas Mensuales', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (_plans.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No hay planes de pago. Añade el primero con el botón (+).'))),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _plans.length,
                      itemBuilder: (context, index) {
                        final plan = _plans[index];
                        return Card(
                          child: ListTile(
                            title: Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(plan.description),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('${plan.amount} ${plan.currency}', style: const TextStyle(fontSize: 16)),
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _showPlanDialog(plan: plan)),
                              IconButton(icon: Icon(Icons.delete, color: Colors.red.shade300), onPressed: () => setState(() => _plans.removeAt(index))),
                            ]),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              floatingActionButton: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton(onPressed: _showPlanDialog, heroTag: 'add_plan_fab', tooltip: 'Añadir Nuevo Plan', child: const Icon(Icons.add)),
                  const SizedBox(height: 16),
                  FloatingActionButton.extended(onPressed: _saveChanges, heroTag: 'save_changes_fab', label: const Text('Guardar Cambios'), icon: const Icon(Icons.save)),
                ],
              ),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: _reportDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al generar el reporte: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No hay datos para mostrar.'));
                }

                final data = snapshot.data!;
                final currency = 'UYU'; // Obtener de financials en el futuro
                final currentMonthTotal = data['currentMonthTotal'] as double;
                final monthlyTotals = data['monthlyTotals'] as Map<int, double>;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text('Ingresos de este mes (${DateFormat('MMMM', 'es_ES').format(DateTime.now())})', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('$currency ${currentMonthTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Historial de Ingresos Anual', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      SizedBox(height: 200, child: _buildBarChart(monthlyTotals, context)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<int, double> monthlyTotals, BuildContext context) {
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    final monthFormatter = DateFormat('MMM', 'es_ES');

    for (int i = 5; i >= 0; i--) { // Mostramos los últimos 6 meses
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = month.year * 100 + month.month;
      final total = monthlyTotals[monthKey] ?? 0.0;

      barGroups.add(BarChartGroupData(
        x: 5 - i,
        barRods: [
          BarChartRodData(toY: total, color: Theme.of(context).primaryColor, width: 16),
        ],
      ));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            final month = DateTime(now.year, now.month - (5 - value.toInt()), 1);
            return Text(monthFormatter.format(month));
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

