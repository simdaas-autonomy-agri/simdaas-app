import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../fertilizers/presentation/providers/fertilizers_providers.dart'
    as fert_provs;

/// Shows a dialog to add/edit a material item and returns the created map or null if cancelled.
Future<Map<String, dynamic>?> showMaterialDialog(BuildContext parentCtx,
    {Map<String, dynamic>? existing}) async {
  // The dialog allows selecting an existing fertilizer mix or creating a new
  // mix. The returned map shape is:
  // { 'mixId': 1, 'name': 'mix name', 'description': '...', 'fertilizers': [{ 'fertilizer': id, 'quantity': num }, ...] }

  // Maintain the current fertilizers list across dialog rebuilds by
  // capturing it in this outer scope (so setStateOuter won't reinitialize
  // it on each rebuild).
  List<Map<String, dynamic>> currentFerts =
      (existing != null && existing['fertilizers'] is List)
          ? List<Map<String, dynamic>>.from(existing['fertilizers'] as List)
          : <Map<String, dynamic>>[];

  // Controllers that must persist across dialog rebuilds
  final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
  final descCtrl = TextEditingController(text: existing?['description'] as String? ?? '');
  final addNameCtrl = TextEditingController();
  final addQtyCtrl = TextEditingController();
  String? selectedIdFromList;
  bool adding = false;

  return await showDialog<Map<String, dynamic>?>(
    context: parentCtx,
    builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateOuter) => Consumer(builder: (c, ref, _) {
        final allFertsAsync = ref.watch(fert_provs.fertilizersListProvider);

              
              

              

              return AlertDialog(
                title: Text(existing == null ? 'Add Material Mix' : 'Edit Material Mix'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mix name & description
                      TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Mix Name')),
                      TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Fertilizers', style: TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Inline fertilizer list
                      allFertsAsync.when(
                        data: (allFerts) {
                          // prepare name lookup
                          final fertNameById = <String, String>{};
                          final fertNames = <String>[];
                          for (final f in allFerts) {
                            final id = (f['id']?.toString() ?? f['pk']?.toString() ?? '');
                            final name = f['name']?.toString() ?? id;
                            fertNameById[id] = name;
                            fertNames.add(name);
                          }

                          // Inline add controls (use outer-scope controllers/vars so their
                          // state persists across rebuilds and we don't shadow them)

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (currentFerts.isEmpty) const Text('No fertilizers added'),
                              if (currentFerts.isNotEmpty)
                                ...currentFerts.map((e) {
                                  final display = (e['name']?.toString() ?? (e['fertilizer'] != null ? (fertNameById[e['fertilizer']?.toString()] ?? e['fertilizer']?.toString()) : 'Unknown')).toString();
                                  return ListTile(
                                    title: Text(display),
                                    subtitle: Text('Qty: ${e['quantity'] ?? ''}'),
                                    trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setStateOuter(() => currentFerts.remove(e))),
                                  );
                                }).toList(),
                              const SizedBox(height: 8),
                              // Add fertilizer inline: Autocomplete + quantity + Add button
                              Row(children: [
                                Expanded(
                                  flex: 3,
                                  child: Autocomplete<String>(
                                    optionsBuilder: (textEditingValue) {
                                      final input = textEditingValue.text.toLowerCase();
                                      if (input.isEmpty) return const Iterable<String>.empty();
                                      return fertNames.where((n) => n.toLowerCase().contains(input));
                                    },
                                    displayStringForOption: (opt) => opt,
                                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                      controller.text = addNameCtrl.text;
                                      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                                      controller.addListener(() { addNameCtrl.text = controller.text; });
                                      return TextFormField(controller: controller, focusNode: focusNode, decoration: const InputDecoration(labelText: 'Fertilizer (type or pick suggestion)'));
                                    },
                                    onSelected: (selection) {
                                      final found = allFerts.firstWhere((f) => (f['name']?.toString() ?? '') == selection, orElse: () => {});
                                      final id = found['id']?.toString() ?? found['pk']?.toString();
                                      selectedIdFromList = id?.toString();
                                      addNameCtrl.text = selection;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(controller: addQtyCtrl, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(onPressed: () async {
                                  if (adding) return;
                                  setStateOuter(() { adding = true; });
                                  try {
                                    var q = double.tryParse(addQtyCtrl.text.trim()) ?? 0.0;
                                    dynamic fertValue;
                                    if (selectedIdFromList != null) {
                                      fertValue = (int.tryParse(selectedIdFromList!) ?? selectedIdFromList!);
                                    } else {
                                      final nameVal = addNameCtrl.text.trim();
                                      if (nameVal.isNotEmpty) {
                                        try {
                                          final controller = ref.read(fert_provs.fertilizerControllerProvider);
                                          final createdF = await controller.createFertilizer({'name': nameVal});
                                          fertValue = (createdF['id'] ?? createdF['pk']) ?? createdF;
                                        } catch (_) {
                                          fertValue = nameVal;
                                        }
                                      } else {
                                        fertValue = addNameCtrl.text.trim();
                                      }
                                    }
                                    setStateOuter(() {
                                      currentFerts.add({'fertilizer': fertValue, 'quantity': q, 'name': addNameCtrl.text.trim()});
                                      addNameCtrl.clear();
                                      addQtyCtrl.clear();
                                      selectedIdFromList = null;
                                    });
                                  } finally {
                                    setStateOuter(() { adding = false; });
                                  }
                                }, child: const Text('Add')),
                              ])
                            ],
                          );
                        },
                        loading: () {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (currentFerts.isEmpty) const Text('No fertilizers added'),
                              if (currentFerts.isNotEmpty)
                                ...currentFerts.map((e) => ListTile(title: Text(e['name']?.toString() ?? e['fertilizer']?.toString() ?? ''), subtitle: Text('Qty: ${e['quantity'] ?? ''}'))).toList(),
                            ],
                          );
                        },
                        error: (e, st) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (currentFerts.isEmpty) const Text('No fertilizers added'),
                            if (currentFerts.isNotEmpty)
                              ...currentFerts.map((e) => ListTile(title: Text(e['name']?.toString() ?? e['fertilizer']?.toString() ?? ''), subtitle: Text('Qty: ${e['quantity'] ?? ''}'))).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () async {
                    final localPayload = {
                      'name': nameCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'fertilizers': currentFerts.map((e) => {'fertilizer': e['fertilizer'], 'quantity': e['quantity']}).toList()
                    };
                    try {
                      final controller = ref.read(fert_provs.fertilizerControllerProvider);
                      showDialog(context: ctx, barrierDismissible: false, builder: (pCtx) => const Center(child: CircularProgressIndicator()));
                      final created = await controller.createMix(localPayload);
                      Navigator.of(ctx).pop();
                      final result = {
                        'mixId': (created['id'] ?? created['pk']),
                        'name': created['name'] ?? localPayload['name'],
                        'description': created['description'] ?? localPayload['description'],
                        'fertilizers': (created['fertilizers'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? currentFerts,
                      };
                      Navigator.of(ctx).pop(result);
                    } catch (e) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(parentCtx).showSnackBar(SnackBar(content: Text('Failed to create mix: $e')));
                    }
                  }, child: const Text('OK'))
                ],
              );
            })),
  );
}
