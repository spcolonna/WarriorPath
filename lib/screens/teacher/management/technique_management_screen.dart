import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/l10n/app_localizations.dart';
import 'package:warrior_path/models/technique_model.dart';

class TechniqueManagementScreen extends StatefulWidget {
  final String schoolId;
  const TechniqueManagementScreen({Key? key, required this.schoolId})
      : super(key: key);

  @override
  State<TechniqueManagementScreen> createState() =>
      _TechniqueManagementScreenState();
}

class _TechniqueManagementScreenState extends State<TechniqueManagementScreen>
    with SingleTickerProviderStateMixin {
  late AppLocalizations l10n;

  bool _isLoading = true;
  List<String> _categories = [];
  List<TechniqueModel> _techniques = [];
  List<TechniqueModel> _initialTechniques = [];

  String _searchQuery = '';
  String? _selectedCategory;

  final _searchController = TextEditingController();

  // Quick-add bar
  final _quickNameController = TextEditingController();
  String? _quickCategory;
  final _quickNameKey = GlobalKey<_ShakeState>();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quickNameController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final schoolDoc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .get();
    _categories =
        List<String>.from(schoolDoc.data()?['techniqueCategories'] ?? []);

    final snap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('techniques')
        .get();
    _techniques = snap.docs.map(TechniqueModel.fromFirestore).toList();
    _initialTechniques =
        _techniques.map(TechniqueModel.fromModel).toList();

    setState(() => _isLoading = false);
  }

  // ── Filtered list ─────────────────────────────────────────────────────────

  List<TechniqueModel> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _techniques.where((t) {
      final matchesSearch = q.isEmpty || t.name.toLowerCase().contains(q);
      final matchesCategory =
          _selectedCategory == null || t.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // ── Quick-add ─────────────────────────────────────────────────────────────

  void _quickAdd() {
    final name = _quickNameController.text.trim();
    if (name.isEmpty) {
      _quickNameKey.currentState?.shake();
      return;
    }
    final category = _quickCategory ??
        (_categories.isNotEmpty ? _categories.first : '');
    final newTech = TechniqueModel(
      name: name,
      category: category,
      complexity: 1,
    );
    setState(() {
      _techniques.insert(0, newTech);
      _quickNameController.clear();
    });
  }

  // ── Edit bottom sheet ─────────────────────────────────────────────────────

  void _showEditSheet(TechniqueModel technique) {
    final model = TechniqueModel.fromModel(technique);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditSheet(
        model: model,
        categories: _categories,
        onSave: () {
          setState(() {
            final idx =
                _techniques.indexWhere((t) => t == technique);
            if (idx != -1) {
              _techniques[idx] = model;
            }
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  // ── Category management ───────────────────────────────────────────────────

  void _showCategoriesSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void add() {
            final name = controller.text.trim();
            if (name.isNotEmpty && !_categories.contains(name)) {
              setSheet(() => _categories.add(name));
              setState(() {});
              controller.clear();
            }
          }

          void remove(String cat) {
            setSheet(() => _categories.remove(cat));
            setState(() {
              if (_selectedCategory == cat) _selectedCategory = null;
              if (_quickCategory == cat) _quickCategory = null;
            });
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.label_outline),
                    const SizedBox(width: 10),
                    Text(
                      'Categorías',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Nueva categoría',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (_) => add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: add,
                      child: const Text('Agregar'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_categories.isEmpty)
                  Text(
                    'Sin categorías aún.',
                    style: TextStyle(color: Colors.grey.shade500),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _categories
                        .map(
                          (cat) => Chip(
                            label: Text(cat),
                            deleteIcon:
                                const Icon(Icons.close, size: 16),
                            onDeleted: () => remove(cat),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _attemptDelete(TechniqueModel technique) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator()),
    );
    try {
      final snap = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('members')
          .where('assignedTechniqueIds', arrayContains: technique.id)
          .limit(10)
          .get();
      if (!mounted) return;
      Navigator.of(context).pop();

      if (snap.docs.isEmpty) {
        if (!mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar borrado'),
            content: Text(
                '¿Eliminar "${technique.name}" permanentemente?'),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.eliminate),
              ),
            ],
          ),
        );
        if (confirm ?? false) {
          setState(() =>
              _techniques.removeWhere((t) => t == technique));
        }
      } else {
        final names = snap.docs
            .map((d) =>
                d.data()['displayName'] as String? ?? 'Alumno')
            .toList();
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('No se puede eliminar "${technique.name}"'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Está asignada a:'),
                const SizedBox(height: 8),
                ...names.map((n) => Text('• $n')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final schoolRef =
          firestore.collection('schools').doc(widget.schoolId);
      final batch = firestore.batch();

      batch.update(schoolRef, {'techniqueCategories': _categories});

      final deletedIds = _initialTechniques
          .map((t) => t.id)
          .toSet()
          .difference(_techniques.map((t) => t.id).toSet());
      for (final id in deletedIds) {
        if (id != null) {
          batch.delete(schoolRef.collection('techniques').doc(id));
        }
      }
      for (final tech in _techniques) {
        if (tech.id == null) {
          batch.set(
              schoolRef.collection('techniques').doc(), tech.toJson());
        } else {
          batch.update(
            schoolRef.collection('techniques').doc(tech.id),
            tech.toJson(),
          );
        }
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Currículo guardado.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final filtered = _isLoading ? <TechniqueModel>[] : _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Técnicas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.label_outline),
            tooltip: 'Categorías',
            onPressed: _isLoading ? null : _showCategoriesSheet,
          ),
          TextButton.icon(
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: const Text(
              'Guardar',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: _isLoading ? null : _saveChanges,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Search bar ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar técnica…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                      isDense: true,
                    ),
                  ),
                ),

                // ── Category filter chips ─────────────────────────────
                if (_categories.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _CategoryChip(
                          label: 'Todas',
                          selected: _selectedCategory == null,
                          color: primary,
                          onTap: () => setState(
                              () => _selectedCategory = null),
                        ),
                        ..._categories.map(
                          (cat) => _CategoryChip(
                            label: cat,
                            selected: _selectedCategory == cat,
                            color: primary,
                            onTap: () => setState(() =>
                                _selectedCategory =
                                    _selectedCategory == cat
                                        ? null
                                        : cat),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Counter ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} técnica${filtered.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // ── Technique list ────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.self_improvement,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Sin resultados para "$_searchQuery"'
                                    : 'Añadí la primera técnica abajo',
                                style: TextStyle(
                                    color: Colors.grey.shade500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (ctx, i) {
                            final tech = filtered[i];
                            return _TechniqueRow(
                              key: ValueKey(
                                  tech.id ?? tech.name + i.toString()),
                              technique: tech,
                              primaryColor: primary,
                              onTap: () => _showEditSheet(tech),
                              onDelete: () => _attemptDelete(tech),
                            );
                          },
                        ),
                ),

                // ── Quick-add bar ─────────────────────────────────────
                _QuickAddBar(
                  nameController: _quickNameController,
                  shakeKey: _quickNameKey,
                  categories: _categories,
                  selectedCategory: _quickCategory,
                  onCategoryChanged: (cat) =>
                      setState(() => _quickCategory = cat),
                  onAdd: _quickAdd,
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick-add bar
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAddBar extends StatelessWidget {
  final TextEditingController nameController;
  final GlobalKey<_ShakeState> shakeKey;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onAdd;

  const _QuickAddBar({
    required this.nameController,
    required this.shakeKey,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottom),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Name field with shake
            Expanded(
              child: _Shake(
                key: shakeKey,
                child: TextField(
                  controller: nameController,
                  onSubmitted: (_) => onAdd(),
                  decoration: InputDecoration(
                    hintText: 'Nombre…',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(width: 6),
              _SmallCategoryDropdown(
                categories: categories,
                value: selectedCategory ?? categories.first,
                onChanged: onCategoryChanged,
              ),
            ],
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                minimumSize: const Size(44, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small category dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _SmallCategoryDropdown extends StatelessWidget {
  final List<String> categories;
  final String value;
  final ValueChanged<String?> onChanged;

  const _SmallCategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = categories.contains(value) ? value : categories.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isDense: true,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
          items: categories
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shake widget
// ─────────────────────────────────────────────────────────────────────────────

class _Shake extends StatefulWidget {
  final Widget child;
  const _Shake({super.key, required this.child});

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void shake() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (ctx, child) {
        final offset =
            math.sin(_animation.value * math.pi * 4) * 6.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chip
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Technique row  (54 px tall, swipe to delete)
// ─────────────────────────────────────────────────────────────────────────────

class _TechniqueRow extends StatelessWidget {
  final TechniqueModel technique;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TechniqueRow({
    super.key,
    required this.technique,
    required this.primaryColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(technique.id ?? technique.name),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade50,
        child: Icon(Icons.delete_outline,
            color: Colors.red.shade400, size: 22),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // let _attemptDelete handle actual removal
      },
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Name + category
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        technique.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (technique.category.isNotEmpty)
                        Text(
                          technique.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Stars (read-only, 14 px)
                _StarDisplay(
                    value: technique.complexity,
                    color: primaryColor),

                const SizedBox(width: 4),

                // Delete button
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: Colors.red.shade300),
                  onPressed: onDelete,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Star display (read-only)
// ─────────────────────────────────────────────────────────────────────────────

class _StarDisplay extends StatelessWidget {
  final int value;
  final Color color;
  const _StarDisplay({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < value ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: i < value ? color : Colors.grey.shade300,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Star picker (interactive, 32 px each)
// ─────────────────────────────────────────────────────────────────────────────

class _StarPicker extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;
  const _StarPicker({required this.initialValue, required this.onChanged});

  @override
  State<_StarPicker> createState() => _StarPickerState();
}

class _StarPickerState extends State<_StarPicker> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        return GestureDetector(
          onTap: () {
            setState(() => _value = starValue);
            widget.onChanged(starValue);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              _value >= starValue
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 32,
              color: _value >= starValue ? color : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditSheet extends StatefulWidget {
  final TechniqueModel model;
  final List<String> categories;
  final VoidCallback onSave;

  const _EditSheet({
    required this.model,
    required this.categories,
    required this.onSave,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _videoCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.model.name);
    _descCtrl =
        TextEditingController(text: widget.model.description);
    _videoCtrl =
        TextEditingController(text: widget.model.videoUrl ?? '');

    // Ensure model category is valid
    if (widget.categories.isNotEmpty &&
        !widget.categories.contains(widget.model.category)) {
      widget.model.category = widget.categories.first;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Editar técnica',
                      style:
                          Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                        20, 16, 20, 16),
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameCtrl,
                        autofocus: true,
                        onChanged: (v) =>
                            widget.model.name = v,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Requerido'
                                : null,
                      ),
                      const SizedBox(height: 14),

                      // Category
                      if (widget.categories.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: widget.categories.contains(
                                  widget.model.category)
                              ? widget.model.category
                              : widget.categories.first,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            border: OutlineInputBorder(),
                          ),
                          items: widget.categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() =>
                                  widget.model.category = v);
                            }
                          },
                        ),
                      const SizedBox(height: 16),

                      // Complexity stars
                      Text(
                        'Complejidad',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      _StarPicker(
                        initialValue: widget.model.complexity,
                        onChanged: (v) =>
                            widget.model.complexity = v,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descCtrl,
                        onChanged: (v) =>
                            widget.model.description = v,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),

                      // Video URL
                      TextFormField(
                        controller: _videoCtrl,
                        onChanged: (v) => widget.model.videoUrl =
                            v.trim().isEmpty ? null : v.trim(),
                        decoration: const InputDecoration(
                          labelText: 'URL de video',
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.play_circle_outline),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      FilledButton(
                        onPressed: () {
                          if (_formKey.currentState
                                  ?.validate() ??
                              false) {
                            widget.onSave();
                          }
                        },
                        style: FilledButton.styleFrom(
                          minimumSize:
                              const Size.fromHeight(48),
                        ),
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
