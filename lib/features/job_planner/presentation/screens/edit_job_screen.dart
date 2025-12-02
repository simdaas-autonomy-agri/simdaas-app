import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/utils/error_utils.dart';
import '../../data/models/job_model.dart';
import '../providers/job_providers.dart';
import '../providers/edit_job_form_provider.dart';
import 'package:simdaas/core/services/auth_service.dart';
// Firestore removed: operators/users are now fetched from REST API
import '../../../plot_mapping/presentation/providers/plot_providers.dart'
    as fm_providers;
import '../../../plot_mapping/data/models/plot_model.dart' as fm_models;
import '../../../auth/presentation/providers/users_providers.dart'
    as users_provs;
import '../../../equipments/presentation/providers/equipment_providers.dart'
    as eq_provs;
import '../widgets/material_dialog.dart';
import 'package:simdaas/core/widgets/api_error_widget.dart';

class EditJobScreen extends ConsumerStatefulWidget {
  final JobModel jobModel;
  const EditJobScreen({super.key, required this.jobModel});

  @override
  ConsumerState<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends ConsumerState<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _acres;
  late TextEditingController _rate;
  late TextEditingController _sprayRateCtrl;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.jobModel.name);
    // New schema fields
    _sprayRateCtrl =
        TextEditingController(text: widget.jobModel.sprayRate?.toString());

    // Initialize form state in Riverpod provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editJobFormProvider(widget.jobModel.id).notifier).reset(
            EditJobFormState(
              operatorId: widget.jobModel.operatorId,
              equipmentId: widget.jobModel
                  .controlUnitId, // equipment dropdown shows control units
              controlUnitId: widget.jobModel.controlUnitId,
              plotId: widget.jobModel.plotId,
              materials: widget.jobModel.productMix ?? [],
              dateTime: widget.jobModel.scheduleTime,
            ),
          );
    });
  }

  // material dialog provided by ../widgets/material_dialog.dart

  @override
  void dispose() {
    _name.dispose();
    _acres.dispose();
    _rate.dispose();
    _sprayRateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(authServiceProvider).currentUserId ?? 'demo_user';
    final plotsAsync = ref.watch(fm_providers.plotsListProvider(userId));
    // users list provider is available where needed in dialogs
    final equipmentsAsync = ref.watch(eq_provs.equipmentsListProvider(userId));
    final formState = ref.watch(editJobFormProvider(widget.jobModel.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Job')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Job name
              TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Job Name')),
              const SizedBox(height: 12),

              // Boundary card (equipment + select boundary)
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
                        Row(children: [
                          Expanded(
                            child: equipmentsAsync.when(
                              data: (items) => DropdownButtonFormField<String>(
                                  value: formState.equipmentId,
                                  decoration: const InputDecoration(
                                      labelText: 'Equipment'),
                                  items: items
                                      .map((e) => DropdownMenuItem(
                                          value: e.id, child: Text(e.name)))
                                      .toList(),
                                  onChanged: (v) => ref
                                      .read(editJobFormProvider(
                                              widget.jobModel.id)
                                          .notifier)
                                      .setEquipmentId(v)),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        if (formState.plotId == null)
                          const Text('No boundary selected'),
                        if (formState.plotId != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: plotsAsync.when(
                              data: (plots) {
                                // plots are PlotModel instances; find matching by id
                                final found = plots
                                    .cast<fm_models.PlotModel?>()
                                    .firstWhere(
                                        (p) => p?.id == formState.plotId,
                                        orElse: () => null);
                                final displayName =
                                    found?.name ?? formState.plotId ?? '';
                                return Text(displayName);
                              },
                              loading: () => const Text('Loading...'),
                              error: (e, st) => ApiErrorWidget(
                                  error: e,
                                  onRetry: () => ref.invalidate(
                                      fm_providers.plotsListProvider(userId))),
                            ),
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              // show boundary selection dialog
                              final picked = await showDialog<String?>(
                                  context: context,
                                  builder: (ctx) {
                                    String? temp = formState.plotId;
                                    return StatefulBuilder(
                                        builder: (ctx2, setStateDialog) {
                                      return AlertDialog(
                                        title: const Text('Select Boundary'),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child: plotsAsync.when(
                                            data: (plots) => ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: plots.length,
                                              itemBuilder: (c, i) {
                                                final f = plots[i];
                                                return RadioListTile<String>(
                                                  title: Text(f.name),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (f.bedHeight != null)
                                                        Text(
                                                            'Bed H: ${f.bedHeight} m'),
                                                      if (f.area != null)
                                                        Text(
                                                            'Area: ${f.area} ha'),
                                                    ],
                                                  ),
                                                  value: f.id,
                                                  groupValue: temp,
                                                  onChanged: (v) =>
                                                      setStateDialog(
                                                          () => temp = v),
                                                );
                                              },
                                            ),
                                            loading: () =>
                                                const SizedBox.shrink(),
                                            error: (e, st) => ApiErrorWidget(
                                                error: e,
                                                onRetry: () => ref.invalidate(
                                                    fm_providers
                                                        .plotsListProvider(
                                                            userId))),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(null),
                                              child: const Text('Cancel')),
                                          ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(temp),
                                              child: const Text('OK'))
                                        ],
                                      );
                                    });
                                  });
                              if (picked != null) {
                                ref
                                    .read(
                                        editJobFormProvider(widget.jobModel.id)
                                            .notifier)
                                    .setPlotId(picked);
                              }
                            },
                            child: const Text('Select Boundary'),
                          ),
                        )
                      ]),
                ),
              ),

              const SizedBox(height: 12),

              // Operator card
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
                        Row(children: [
                          Expanded(
                            child: formState.operatorId == null
                                ? const Text('No operator selected')
                                : Consumer(builder: (c, ref2, _) {
                                    final opsAsync = ref2.watch(
                                        users_provs.operatorsListProvider);
                                    return opsAsync.when(
                                      data: (list) {
                                        try {
                                          // normalize list to map by string id to avoid duplicates
                                          final Map<String,
                                              Map<String, dynamic>> byId = {};
                                          for (final u in list) {
                                            final m = Map<String, dynamic>.from(
                                                u as Map);
                                            final idRaw = m['id'] ?? m['pk'];
                                            if (idRaw == null) continue;
                                            final idStr = idRaw.toString();
                                            if (idStr.isEmpty) continue;
                                            if (!byId.containsKey(idStr))
                                              byId[idStr] = m;
                                          }
                                          final found =
                                              byId[formState.operatorId];
                                          final name = found == null
                                              ? formState.operatorId
                                              : (found['name'] as String?) ??
                                                  found['email'] ??
                                                  formState.operatorId;
                                          return Text('Selected: $name');
                                        } catch (_) {
                                          return Text(
                                              'Selected: ${formState.operatorId}');
                                        }
                                      },
                                      loading: () => const Text('Loading...'),
                                      error: (_, __) => Text(
                                          'Selected: ${formState.operatorId}'),
                                    );
                                  }),
                          ),
                          TextButton(
                              onPressed: () =>
                                  _openSelectOperatorDialog(context),
                              child: const Text('Select Operator')),
                          const SizedBox(width: 8),
                          TextButton(
                              onPressed: () => _openAddOperatorDialog(context),
                              child: const Text('Add New Operator')),
                        ])
                      ]),
                ),
              ),

              const SizedBox(height: 12),

              // Spray details
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
                        // Control unit selection
                        equipmentsAsync.when(
                          data: (items) {
                            final controlUnits = items
                                .where((e) => e.category == 'control_unit')
                                .toList();
                            final hasSel = formState.controlUnitId != null &&
                                controlUnits
                                        .where((e) =>
                                            e.id == formState.controlUnitId)
                                        .length ==
                                    1;
                            final effective =
                                hasSel ? formState.controlUnitId : null;
                            return DropdownButtonFormField<String>(
                              value: effective,
                              decoration: const InputDecoration(
                                  labelText: 'Control unit'),
                              items: controlUnits
                                  .map((e) => DropdownMenuItem(
                                      value: e.id,
                                      child: Text(
                                          '${e.name}${e.controlUnitId != null ? ' (${e.controlUnitId})' : ''}')))
                                  .toList(),
                              onChanged: (v) => ref
                                  .read(editJobFormProvider(widget.jobModel.id)
                                      .notifier)
                                  .setControlUnitId(v),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                            controller: _sprayRateCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Spray Rate'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true)),
                        const SizedBox(height: 8),
                        const Text('Products / Materials',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Column(
                            children: formState.materials
                                .asMap()
                                .entries
                                .map((entry) {
                          final idx = entry.key;
                          final m = entry.value;
                          final ferts = m['fertilizers'] as List<dynamic>?;
                          return Card(
                            child: ListTile(
                              title: Text(
                                  m['name'] ?? m['mixName'] ?? 'Unnamed mix'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (ferts == null || ferts.isEmpty)
                                    const Text('No fertilizers'),
                                  if (ferts != null && ferts.isNotEmpty)
                                    ...ferts.map((f) => Text(
                                        '${f['name'] ?? f['fertilizer'] ?? ''} — Qty: ${f['quantity'] ?? ''}'))
                                ],
                              ),
                              trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => ref
                                      .read(editJobFormProvider(
                                              widget.jobModel.id)
                                          .notifier)
                                      .removeMaterial(idx)),
                            ),
                          );
                        }).toList()),
                        Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                                onPressed: () async {
                                  final mat = await showMaterialDialog(context);
                                  if (mat != null) {
                                    ref
                                        .read(editJobFormProvider(
                                                widget.jobModel.id)
                                            .notifier)
                                        .addMaterial(mat);
                                  }
                                },
                                child: const Text('Add Material'))),
                        const SizedBox(height: 8),
                        // Date/time pickers
                        Row(children: [
                          Expanded(
                              child: OutlinedButton.icon(
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(formState.dateTime == null
                                      ? 'Select date'
                                      : formState.dateTime!
                                          .toLocal()
                                          .toIso8601String()
                                          .split('T')
                                          .first),
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final initial = formState.dateTime ?? now;
                                    final picked = await showDatePicker(
                                        context: context,
                                        initialDate: initial,
                                        firstDate: DateTime(now.year - 5),
                                        lastDate: DateTime(now.year + 5));
                                    if (picked == null) return;
                                    final timePart = formState.dateTime ?? now;
                                    if (!mounted) return;
                                    ref
                                        .read(editJobFormProvider(
                                                widget.jobModel.id)
                                            .notifier)
                                        .setDateTime(DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                            timePart.hour,
                                            timePart.minute));
                                  })),
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
                                        formState.dateTime ?? DateTime.now();
                                    if (!mounted) return;
                                    ref
                                        .read(editJobFormProvider(
                                                widget.jobModel.id)
                                            .notifier)
                                        .setDateTime(DateTime(
                                            datePart.year,
                                            datePart.month,
                                            datePart.day,
                                            picked.hour,
                                            picked.minute));
                                  })),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                              child: TextButton(
                                  onPressed: () async {
                                    if (_formKey.currentState == null ||
                                        !_formKey.currentState!.validate())
                                      return;
                                    // validation
                                    final plotToUse = formState.plotId ??
                                        widget.jobModel.plotId;
                                    final controlToUse =
                                        formState.controlUnitId ??
                                            widget.jobModel.controlUnitId;
                                    final operatorToUse =
                                        formState.operatorId ??
                                            widget.jobModel.operatorId;
                                    if (plotToUse == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Please select a plot')));
                                      return;
                                    }
                                    if (controlToUse == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Please select a control unit')));
                                      return;
                                    }
                                    if (operatorToUse == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Please select an operator')));
                                      return;
                                    }
                                    final sprayText =
                                        _sprayRateCtrl.text.trim();
                                    if (sprayText.isNotEmpty &&
                                        double.tryParse(sprayText) == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Spray rate must be a number')));
                                      return;
                                    }
                                    final dt =
                                        formState.dateTime ?? DateTime.now();
                                    // determine canonical scheduled time if needed
                                    final repo = ref.read(jobRepoProvider);
                                    final updated = JobModel(
                                      id: widget.jobModel.id,
                                      name: _name.text.trim(),
                                      userId: userId,
                                      plotId: plotToUse,
                                      controlUnitId: controlToUse,
                                      createdAt: widget.jobModel.createdAt,
                                      scheduleTime: dt,
                                      operatorId: operatorToUse,
                                      sprayRate:
                                          double.tryParse(_sprayRateCtrl.text),
                                      productMix: formState.materials,
                                      status: widget.jobModel.status,
                                    );
                                    await repo.updateJob(updated);
                                    ref.invalidate(jobsListProvider(userId));
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Save'))),
                        ]),
                      ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSelectOperatorDialog(BuildContext parentCtx) async {
    String? tempSelected =
        ref.read(editJobFormProvider(widget.jobModel.id)).operatorId;

    final picked = await showDialog<String?>(
      context: parentCtx,
      builder: (ctx) {
        return Consumer(builder: (c, ref2, _) {
          final opsAsync = ref2.watch(users_provs.operatorsListProvider);
          return opsAsync.when(
            data: (docs) {
              return StatefulBuilder(builder: (ctx2, setStateDialog) {
                return AlertDialog(
                  title: const Text('Select Operator'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: docs.isEmpty
                        ? const Text('No operators found')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: docs.length,
                            itemBuilder: (c, i) {
                              final doc =
                                  Map<String, dynamic>.from(docs[i] as Map);
                              final idStr =
                                  (doc['id'] ?? doc['pk'])?.toString() ?? '';
                              if (idStr.isEmpty) return const SizedBox.shrink();
                              final name = (doc['name'] as String?) ??
                                  doc['email'] ??
                                  idStr;
                              final phone = (doc['phone'] as String?) ?? '';
                              return RadioListTile<String>(
                                title: Text(name),
                                subtitle: Text(phone),
                                value: idStr,
                                groupValue: tempSelected,
                                onChanged: (v) =>
                                    setStateDialog(() => tempSelected = v),
                              );
                            },
                          ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          // open add operator dialog
                          final newId = await _openAddOperatorDialog(parentCtx);
                          if (newId != null) Navigator.of(parentCtx).pop(newId);
                        },
                        child: const Text('Add New Operator')),
                    ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(tempSelected),
                        child: const Text('OK')),
                  ],
                );
              });
            },
            loading: () => const AlertDialog(
                title: Text('Select Operator'),
                content: SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()))),
            error: (e, st) => AlertDialog(
                title: const Text('Select Operator'),
                content: SizedBox(
                    width: double.maxFinite, child: ApiErrorWidget(error: e)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      child: const Text('OK'))
                ]),
          );
        });
      },
    );

    if (picked != null)
      ref
          .read(editJobFormProvider(widget.jobModel.id).notifier)
          .setOperatorId(picked);
  }

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
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full name'),
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
                      decoration: const InputDecoration(labelText: 'Address')),
                  TextFormField(
                      controller: experienceCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Experience (years)'),
                      keyboardType: TextInputType.number),
                  TextFormField(
                      controller: assignedMachineCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Assigned machine')),
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
                ]),
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

    if (result != null)
      ref
          .read(editJobFormProvider(widget.jobModel.id).notifier)
          .setOperatorId(result);
    return result;
  }
}
