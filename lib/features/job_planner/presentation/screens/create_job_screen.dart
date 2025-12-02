import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/utils/error_utils.dart';
import '../../data/models/job_model.dart';
import '../../domain/entities/job.dart';
import '../providers/job_providers.dart';
import '../providers/create_job_form_provider.dart';
import 'package:simdaas/core/services/auth_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../auth/presentation/providers/users_providers.dart'
    as users_provs;
import '../../../plot_mapping/presentation/providers/plot_providers.dart'
    as fm_providers;
import '../../../fertilizers/presentation/providers/fertilizers_providers.dart'
    as fert_provs;
// applications removed from job flow
import '../../../plot_mapping/data/models/plot_model.dart' as fm_models;
import '../../../equipments/presentation/providers/equipment_providers.dart'
    as eq_provs;
import '../widgets/material_dialog.dart';
import 'package:simdaas/core/widgets/api_error_widget.dart';

// Operator roles removed — add-operator dialog simplified to name + contact number

class CreateJobScreen extends ConsumerStatefulWidget {
  const CreateJobScreen({super.key});

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sprayRateController = TextEditingController();
  // State now managed by Riverpod provider instead of local state
  // applications removed from job flow
  // equipment selection removed from job flow

  // Roles for users/operators (defined at file level)

  // Operator selection dialog removed: operator selection is now a Dropdown

  Future<String?> _openAddOperatorDialog(BuildContext parentCtx) async {
    final formKeyOp = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final experienceCtrl = TextEditingController();
    final assignedMachineCtrl = TextEditingController();
    final shiftTimingCtrl = TextEditingController();
    bool isActive = true;

    final result = await showDialog<String?>(
      context: parentCtx,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setStateDialog) {
          final creatingNotifier = ValueNotifier<bool>(false);
          return AlertDialog(
            title: const Text('Add New Operator'),
            content: SingleChildScrollView(
              child: Form(
                key: formKeyOp,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                        controller: nameCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Full name'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter name' : null),
                    TextFormField(
                        controller: phoneCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Contact number'),
                        keyboardType: TextInputType.phone),
                    TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress),
                    TextFormField(
                        controller: addressCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Address')),
                    TextFormField(
                        controller: experienceCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Experience (years)'),
                        keyboardType: TextInputType.number),
                    TextFormField(
                        controller: assignedMachineCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Assigned machine')),
                    TextFormField(
                        controller: shiftTimingCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Shift timing')),
                    Row(
                      children: [
                        const Text('Active'),
                        const Spacer(),
                        Switch(
                          value: isActive,
                          onChanged: (v) => setStateDialog(() => isActive = v),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel')),
              ValueListenableBuilder<bool>(
                valueListenable: creatingNotifier,
                builder: (context, creatingValue, _) {
                  return creatingValue
                      ? const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : const SizedBox.shrink();
                },
              ),
              ElevatedButton(
                  onPressed: () async {
                    if (creatingNotifier.value) return;
                    if (formKeyOp.currentState == null ||
                        !formKeyOp.currentState!.validate()) return;
                    creatingNotifier.value = true;
                    try {
                      final opId = await ref
                          .read(users_provs.operatorsControllerProvider)
                          .createOperator(
                              name: nameCtrl.text.trim(),
                              contactNumber: phoneCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              address: addressCtrl.text.trim(),
                              experienceYears:
                                  int.tryParse(experienceCtrl.text.trim()),
                              assignedMachine: assignedMachineCtrl.text.trim(),
                              shiftTiming: shiftTimingCtrl.text.trim(),
                              isActive: isActive);
                      ref.invalidate(users_provs.operatorsListProvider);
                      if (ctx.mounted)
                        ScaffoldMessenger.of(parentCtx).showSnackBar(
                            const SnackBar(content: Text('Created operator')));
                      Navigator.of(ctx).pop(opId);
                    } catch (e) {
                      if (ctx.mounted)
                        showPolishedError(parentCtx, e,
                            fallback: 'Failed to create user');
                      creatingNotifier.value = false;
                    }
                  },
                  child: const Text('Create')),
            ],
          );
        });
      },
    );

    if (result != null) {
      // Wait for the operators provider to refresh and ensure the created
      // operator appears in the latest list before selecting it. This
      // avoids a race where a refetch briefly yields duplicates or a
      // transient state that triggers the Dropdown assertion.
      final createdId = result.toString();
      try {
        // Trigger a refresh and await the fresh list (safe to await; if it
        // errors we fall back to selecting immediately).
        ref.invalidate(users_provs.operatorsListProvider);
        final latest = await ref.read(users_provs.operatorsListProvider.future);
        final exists = latest.any((m) =>
            (m['id']?.toString() ?? m['pk']?.toString() ?? '') == createdId);
        if (exists) {
          if (mounted)
            ref.read(createJobFormProvider.notifier).setOperatorId(createdId);
        } else {
          // fallback: still set it (rare) — but do so on next frame to avoid assertion
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted)
              ref.read(createJobFormProvider.notifier).setOperatorId(createdId);
          });
        }
      } catch (_) {
        // if provider read failed, set selected id defensively on next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted)
            ref.read(createJobFormProvider.notifier).setOperatorId(createdId);
        });
      }
    }
    return result;
  }

  // Map controller for the map preview
  final MapController _mapController = MapController();

  void _centerMapToSelected(List fields) {
    final plotId = ref.read(createJobFormProvider).plotId;
    if (plotId == null) return;
    try {
      final model = fields.cast<fm_models.PlotModel>().firstWhere(
          (f) => f.id == plotId,
          orElse: () => fm_models.PlotModel(
              id: plotId,
              name: plotId,
              userId: '',
              bedHeight: null,
              polygon: [],
              area: null));
      if (model.polygon.isNotEmpty) {
        final avgLat =
            model.polygon.map((p) => p.latitude).reduce((a, b) => a + b) /
                model.polygon.length;
        final avgLng =
            model.polygon.map((p) => p.longitude).reduce((a, b) => a + b) /
                model.polygon.length;
        final center = LatLng(avgLat, avgLng);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            _mapController.move(center, 13.0);
          } catch (_) {}
        });
      }
    } catch (_) {}
  }

  // operators are loaded from Firestore 'users' collection when needed

  // Applications state
  // ...applications removed (not part of job for now)

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(authServiceProvider).currentUserId ?? 'demo_user';
    // userId used as job owner
    final fieldsAsync = ref.watch(fm_providers.plotsListProvider(userId));
    final formState = ref.watch(createJobFormProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Job')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Job Name')),
              ]),
            ),
            const SizedBox(height: 12),
            // Sections: Boundaries / Operators / General
            Expanded(
              child: fieldsAsync.when(
                data: (fields) => ListView(
                  children: [
                    // Applications removed from job flow per request
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Boundary',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const SizedBox(height: 8),
                            // show selected site
                            if (formState.plotId == null)
                              const Text('No boundary selected'),
                            if (formState.plotId != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  (fields
                                      .cast<fm_models.PlotModel>()
                                      .firstWhere(
                                        (f) => f.id == formState.plotId,
                                        orElse: () => fm_models.PlotModel(
                                          id: formState.plotId!,
                                          name: formState.plotId!,
                                          userId: '',
                                          bedHeight: null,
                                          polygon: [],
                                          area: null,
                                        ),
                                      )
                                      .name),
                                ),
                              ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  onPressed: () async {
                                    // open dialog to pick a single boundary from plots
                                    final picked = await showDialog<String?>(
                                        context: context,
                                        builder: (ctx) {
                                          String? temp = formState.plotId;
                                          return StatefulBuilder(
                                            builder: (ctx2, setStateDialog) =>
                                                AlertDialog(
                                              title:
                                                  const Text('Select Boundary'),
                                              content: SizedBox(
                                                width: double.maxFinite,
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  itemCount: fields.length,
                                                  itemBuilder: (c, i) {
                                                    final f = fields[i]
                                                        as fm_models.PlotModel;
                                                    return RadioListTile<
                                                        String>(
                                                      title: Text(f.name),
                                                      subtitle: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (f.bedHeight !=
                                                              null)
                                                            Text(
                                                                'Bed H: ${f.bedHeight} m'),
                                                          if (f.area != null)
                                                            Text(
                                                                'Area: ${f.area} ha'),
                                                        ],
                                                      ),
                                                      value: f.id,
                                                      groupValue: temp,
                                                      onChanged: (v) {
                                                        setStateDialog(() {
                                                          temp = v;
                                                        });
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(null),
                                                    child:
                                                        const Text('Cancel')),
                                                ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(temp),
                                                    child: const Text('OK'))
                                              ],
                                            ),
                                          );
                                        });
                                    if (picked != null) {
                                      ref
                                          .read(createJobFormProvider.notifier)
                                          .setPlotId(picked);
                                      // center map on selected boundary
                                      _centerMapToSelected(fields);
                                    }
                                  },
                                  child: const Text('Select Boundary')),
                            )
                          ],
                        ),
                      ),
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Operator',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(
                                child: Consumer(builder: (c, ref2, _) {
                                  final opsAsync = ref2
                                      .watch(users_provs.operatorsListProvider);
                                  return opsAsync.when(
                                    data: (list) {
                                      // normalize and dedupe by id string (keep first occurrence)
                                      final Map<String, Map<String, dynamic>>
                                          byId = {};
                                      for (final opRaw in list) {
                                        final op = Map<String, dynamic>.from(
                                            opRaw as Map);
                                        final idRaw = op['id'] ?? op['pk'];
                                        if (idRaw == null) continue;
                                        final id = idRaw.toString();
                                        if (id.isEmpty)
                                          continue; // skip empty ids
                                        if (!byId.containsKey(id))
                                          byId[id] = op;
                                      }
                                      // Build a map of DropdownMenuItem by value to forcibly collapse duplicates
                                      final Map<String,
                                              DropdownMenuItem<String>>
                                          itemByValue = {};
                                      // no debug checks
                                      for (final op in byId.values) {
                                        final idStr = (op['id'] ?? op['pk'])
                                                ?.toString() ??
                                            '';
                                        if (idStr.isEmpty) continue;
                                        // last write wins: prefer the existing entry (keeps first occurrence)
                                        if (!itemByValue.containsKey(idStr)) {
                                          final name =
                                              (op['name'] as String?) ??
                                                  op['email'] ??
                                                  idStr;
                                          itemByValue[idStr] =
                                              DropdownMenuItem<String>(
                                                  value: idStr,
                                                  child: Text(name));
                                        }
                                      }

                                      final items = itemByValue.values
                                          .toList(growable: false);

                                      // If the selected value does not match exactly one item, clear it to avoid assertion.
                                      final matchCount = items
                                          .where((it) =>
                                              it.value == formState.operatorId)
                                          .length;
                                      if (matchCount != 1 &&
                                          formState.operatorId != null) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (mounted)
                                            ref
                                                .read(createJobFormProvider
                                                    .notifier)
                                                .setOperatorId(null);
                                        });
                                      }

                                      return DropdownButtonFormField<String>(
                                        value: formState.operatorId,
                                        decoration: const InputDecoration(
                                            labelText: 'Operator'),
                                        items: items,
                                        onChanged: (v) => ref
                                            .read(
                                                createJobFormProvider.notifier)
                                            .setOperatorId(v?.toString()),
                                      );
                                    },
                                    loading: () => const Text('Loading...'),
                                    error: (_, __) => Text(
                                        'Selected: ${formState.operatorId}'),
                                  );
                                }),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                  onPressed: () =>
                                      _openAddOperatorDialog(context),
                                  child: const Text('Add New')),
                            ]),
                          ],
                        ),
                      ),
                    ),

                    // Control unit (separated from spray details)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Control Unit',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(
                                child: Consumer(builder: (c, ref2, _) {
                                  // Use the dedicated controlUnitsProvider so we only
                                  // fetch control units instead of all equipment.
                                  final currentUserId = ref2
                                          .read(authServiceProvider)
                                          .currentUserId ??
                                      'demo_user';
                                  final cuAsync = ref2.watch(eq_provs
                                      .controlUnitsProvider(currentUserId));
                                  return cuAsync.when(
                                      data: (items) {
                                        // items are already control units
                                        return DropdownButtonFormField<String>(
                                          value: formState.controlUnitId,
                                          decoration: const InputDecoration(
                                              labelText: 'Control unit'),
                                          items: items
                                              .map((e) => DropdownMenuItem(
                                                  value: e.id,
                                                  child: Text(
                                                      '${e.name}${e.controlUnitId != null ? ' (${e.controlUnitId})' : ''}')))
                                              .toList(),
                                          onChanged: (v) => ref
                                              .read(createJobFormProvider
                                                  .notifier)
                                              .setControlUnitId(v),
                                        );
                                      },
                                      loading: () => const SizedBox.shrink(),
                                      error: (_, __) =>
                                          const SizedBox.shrink());
                                }),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),

                    // Spray details: spray rate and product/material list
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Spray Details',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _sprayRateController,
                              decoration: const InputDecoration(
                                  labelText: 'Spray Rate'),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                            ),
                            const SizedBox(height: 8),
                            const Text('Products / Materials',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            // Resolve fertilizer names from the global fertilizers
                            // list provider so we always display names (not ids).
                            Consumer(builder: (c, ref2, _) {
                              final allFertsAsync = ref2
                                  .watch(fert_provs.fertilizersListProvider);
                              return allFertsAsync.when(data: (allFerts) {
                                return Column(
                                  children: formState.materials
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final idx = entry.key;
                                    final m = entry.value;
                                    final ferts =
                                        m['fertilizers'] as List<dynamic>?;
                                    return Card(
                                      child: ListTile(
                                        title: Text(m['name'] ??
                                            m['mixName'] ??
                                            'Unnamed mix'),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (ferts == null || ferts.isEmpty)
                                              const Text('No fertilizers'),
                                            if (ferts != null &&
                                                ferts.isNotEmpty)
                                              ...ferts.map((f) {
                                                final fid = f['fertilizer']
                                                        ?.toString() ??
                                                    '';
                                                final found = allFerts.firstWhere(
                                                    (af) =>
                                                        (af['id']?.toString() ??
                                                            af['pk']
                                                                ?.toString() ??
                                                            '') ==
                                                        fid,
                                                    orElse: () =>
                                                        <String, dynamic>{});
                                                final foundName =
                                                    found['name']?.toString();
                                                final display =
                                                    f['name']?.toString() ??
                                                        foundName ??
                                                        (fid.isNotEmpty
                                                            ? fid
                                                            : 'Unnamed');
                                                return Text(
                                                    '$display — Qty: ${f['quantity'] ?? ''}');
                                              }).toList()
                                          ],
                                        ),
                                        trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => ref
                                                .read(createJobFormProvider
                                                    .notifier)
                                                .removeMaterial(idx)),
                                      ),
                                    );
                                  }).toList(),
                                );
                              }, loading: () {
                                // Render items but fall back to raw name/id while loading
                                return Column(
                                  children: formState.materials
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final idx = entry.key;
                                    final m = entry.value;
                                    final ferts =
                                        m['fertilizers'] as List<dynamic>?;
                                    return Card(
                                      child: ListTile(
                                        title: Text(m['name'] ??
                                            m['mixName'] ??
                                            'Unnamed mix'),
                                        subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (ferts == null ||
                                                  ferts.isEmpty)
                                                const Text('No fertilizers'),
                                              if (ferts != null &&
                                                  ferts.isNotEmpty)
                                                ...ferts
                                                    .map((f) => Text(
                                                        '${f['name']?.toString() ?? f['fertilizer']?.toString() ?? ''} — Qty: ${f['quantity'] ?? ''}'))
                                                    .toList()
                                            ]),
                                        trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => ref
                                                .read(createJobFormProvider
                                                    .notifier)
                                                .removeMaterial(idx)),
                                      ),
                                    );
                                  }).toList(),
                                );
                              }, error: (e, st) {
                                // If fertilizer list failed to load, still render raw entries
                                return Column(
                                  children: formState.materials
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final idx = entry.key;
                                    final m = entry.value;
                                    final ferts =
                                        m['fertilizers'] as List<dynamic>?;
                                    return Card(
                                      child: ListTile(
                                        title: Text(m['name'] ??
                                            m['mixName'] ??
                                            'Unnamed mix'),
                                        subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (ferts == null ||
                                                  ferts.isEmpty)
                                                const Text('No fertilizers'),
                                              if (ferts != null &&
                                                  ferts.isNotEmpty)
                                                ...ferts
                                                    .map((f) => Text(
                                                        '${f['name']?.toString() ?? f['fertilizer']?.toString() ?? ''} — Qty: ${f['quantity'] ?? ''}'))
                                                    .toList()
                                            ]),
                                        trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => ref
                                                .read(createJobFormProvider
                                                    .notifier)
                                                .removeMaterial(idx)),
                                      ),
                                    );
                                  }).toList(),
                                );
                              });
                            }),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Compact picker: choose existing mix and add immediately
                                  TextButton(
                                      onPressed: () async {
                                        try {
                                          final mixes = await ref.read(
                                              fert_provs.fertilizerMixesProvider
                                                  .future);
                                          final safeMixes = mixes;
                                          // show simple picker
                                          final picked = await showDialog<
                                              Map<String, dynamic>?>(
                                            context: context,
                                            builder: (ctx) {
                                              return AlertDialog(
                                                title: const Text(
                                                    'Select existing mix'),
                                                content: SizedBox(
                                                  width: double.maxFinite,
                                                  child: ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount: safeMixes.length,
                                                    itemBuilder: (c, i) {
                                                      final m = safeMixes[i];
                                                      final mid = (m['id']
                                                              ?.toString() ??
                                                          m['pk']?.toString() ??
                                                          '');
                                                      return ListTile(
                                                        title: Text(m['name']
                                                                ?.toString() ??
                                                            ''),
                                                        subtitle: m['description'] !=
                                                                null
                                                            ? Text(
                                                                m['description']
                                                                    .toString())
                                                            : null,
                                                        onTap: () {
                                                          Navigator.of(ctx)
                                                              .pop({
                                                            'mixId':
                                                                int.tryParse(
                                                                        mid) ??
                                                                    mid,
                                                            'name':
                                                                m['name'] ?? '',
                                                            'description':
                                                                m['description'] ??
                                                                    '',
                                                            'fertilizers': (m[
                                                                            'fertilizers']
                                                                        as List?)
                                                                    ?.map((e) => Map<
                                                                            String,
                                                                            dynamic>.from(
                                                                        e
                                                                            as Map))
                                                                    .toList() ??
                                                                <Map<String,
                                                                    dynamic>>[],
                                                          });
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx)
                                                              .pop(null),
                                                      child:
                                                          const Text('Cancel')),
                                                ],
                                              );
                                            },
                                          );
                                          if (picked != null) {
                                            ref
                                                .read(createJobFormProvider
                                                    .notifier)
                                                .addMaterial(picked);
                                          }
                                        } catch (e) {
                                          showPolishedError(context, e,
                                              fallback: 'Failed to load mixes');
                                        }
                                      },
                                      child: const Text('Select existing mix')),
                                  const SizedBox(width: 8),
                                  TextButton(
                                      onPressed: () async {
                                        final newMat =
                                            await showMaterialDialog(context);
                                        if (newMat != null)
                                          ref
                                              .read(createJobFormProvider
                                                  .notifier)
                                              .addMaterial(newMat);
                                      },
                                      child: const Text('Add Material')),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Date & Time pickers (kept here)
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon:
                                              const Icon(Icons.calendar_today),
                                          label: Text(formState.dateTime == null
                                              ? 'Select date'
                                              : formState.dateTime!
                                                  .toLocal()
                                                  .toIso8601String()
                                                  .split('T')
                                                  .first),
                                          onPressed: () async {
                                            final now = DateTime.now();
                                            final initial =
                                                formState.dateTime ?? now;
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: initial,
                                              firstDate: DateTime(now.year - 5),
                                              lastDate: DateTime(now.year + 5),
                                            );
                                            if (picked == null) return;
                                            final timePart =
                                                formState.dateTime ?? now;
                                            final combined = DateTime(
                                                picked.year,
                                                picked.month,
                                                picked.day,
                                                timePart.hour,
                                                timePart.minute);
                                            if (!mounted) return;
                                            ref
                                                .read(createJobFormProvider
                                                    .notifier)
                                                .setDateTime(combined);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.access_time),
                                          label: Text(formState.dateTime == null
                                              ? 'Select time'
                                              : TimeOfDay.fromDateTime(
                                                      formState.dateTime!)
                                                  .format(context)),
                                          onPressed: () async {
                                            final now = DateTime.now();
                                            final initialTime =
                                                formState.dateTime != null
                                                    ? TimeOfDay.fromDateTime(
                                                        formState.dateTime!)
                                                    : TimeOfDay(
                                                        hour: now.hour,
                                                        minute: now.minute);
                                            final picked = await showTimePicker(
                                                context: context,
                                                initialTime: initialTime);
                                            if (picked == null) return;
                                            final datePart =
                                                formState.dateTime ??
                                                    DateTime.now();
                                            final combined = DateTime(
                                                datePart.year,
                                                datePart.month,
                                                datePart.day,
                                                picked.hour,
                                                picked.minute);
                                            if (!mounted) return;
                                            ref
                                                .read(createJobFormProvider
                                                    .notifier)
                                                .setDateTime(combined);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () async {
                                      // Validate form (basic validation for name)
                                      if (_formKey.currentState == null ||
                                          !_formKey.currentState!.validate())
                                        return;

                                      // Ensure we have a date/time for the job
                                      final dt =
                                          formState.dateTime ?? DateTime.now();

                                      // Determine status from date/time
                                      // build job with scheduleTime/createdAt
                                      // Client-side validation
                                      if (formState.plotId == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Please select a plot')));
                                        return;
                                      }
                                      if (formState.controlUnitId == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Please select a control unit')));
                                        return;
                                      }
                                      if (formState.operatorId == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Please select an operator')));
                                        return;
                                      }
                                      // ownerId is legacy; userId is set above

                                      // Build the JobModel and create it
                                      final job = JobModel(
                                        id: '',
                                        name: _name.text.trim(),
                                        userId: userId,
                                        plotId: formState.plotId,
                                        controlUnitId: formState.controlUnitId,
                                        createdAt: DateTime.now(),
                                        scheduleTime: dt,
                                        operatorId: formState.operatorId,
                                        sprayRate: double.tryParse(
                                            _sprayRateController.text),
                                        productMix: formState.materials,
                                        status: JobStatus.scheduled,
                                      );

                                      final repo = ref.read(jobRepoProvider);
                                      await repo.createJob(job);
                                      // Invalidate jobs list for the current user so lists refresh
                                      try {
                                        ref.invalidate(
                                            jobsListProvider(userId));
                                      } catch (_) {}
                                      if (mounted) {
                                        ref
                                            .read(
                                                createJobFormProvider.notifier)
                                            .reset();
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    child: const Text('Create Job'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Map preview of selected boundaries
                    SizedBox(
                      height: 220,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: formState.plotId != null
                              ? (fields
                                  .cast<fm_models.PlotModel>()
                                  .firstWhere((f) => f.id == formState.plotId)
                                  .polygon
                                  .first)
                              : LatLng(51.5, -0.09),
                          initialZoom: 18.0,
                        ),
                        children: [
                          TileLayer(
                              urlTemplate:
                                  'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                              subdomains: const ['a', 'b', 'c']),
                          for (final f in (fields
                              .cast<fm_models.PlotModel>()
                              .where((fm) => fm.id == formState.plotId)))
                            PolygonLayer(polygons: [
                              Polygon(
                                  points: f.polygon,
                                  color: Colors.green.withOpacity(0.25),
                                  borderColor: Colors.green,
                                  borderStrokeWidth: 2.0)
                            ])
                        ],
                      ),
                    )
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => ApiErrorWidget(
                    error: e,
                    onRetry: () =>
                        ref.invalidate(fm_providers.plotsListProvider(userId))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Application helper dialogs removed

  // material dialog now provided by ../widgets/material_dialog.dart
}
