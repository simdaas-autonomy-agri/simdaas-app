import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/equipment_providers.dart';
import 'package:simdaas/core/services/auth_service.dart';
import 'dart:convert';
import 'package:simdaas/core/services/api_exception.dart';

class CreateTractorScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingData;
  const CreateTractorScreen({super.key, this.existingData});

  @override
  ConsumerState<CreateTractorScreen> createState() =>
      _CreateTractorScreenState();
}

class _CreateTractorScreenState extends ConsumerState<CreateTractorScreen> {
  bool _debugShown = false;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _wheelDiameter = TextEditingController();
  final _screwsInWheel = TextEditingController();
  final _axleLength = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _wheelDiameter.dispose();
    _screwsInWheel.dispose();
    _axleLength.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_debugShown && mounted) {
          debugPrint(
              'CreateTractorScreen existingData: ${widget.existingData}');
          _debugShown = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingData != null;
    if (isEditing) {
      final ex = widget.existingData!;
      _name.text = ex['name'] as String? ?? '';
      if (ex['wheelDiameter'] != null)
        _wheelDiameter.text = '${ex['wheelDiameter']}';
      if (ex['screwsInWheel'] != null)
        _screwsInWheel.text = '${ex['screwsInWheel']}';
      if (ex['axleLength'] != null) _axleLength.text = '${ex['axleLength']}';
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Tractor' : 'Add Tractor')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration:
                        const InputDecoration(labelText: 'Tractor name'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _wheelDiameter,
                    decoration:
                        const InputDecoration(labelText: 'Wheel diameter (m)'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter wheel diameter' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _screwsInWheel,
                    decoration: const InputDecoration(
                        labelText: 'Number of screws in wheel'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter number of screws' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _axleLength,
                    decoration:
                        const InputDecoration(labelText: 'Axle length (m)'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter axle length' : null,
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final ctrl = ref.read(equipmentControllerProvider);
                        final navigator = Navigator.of(context);
                        double? wheelDiameter;
                        int? screwsInWheel;
                        double? axleLength;
                        try {
                          wheelDiameter = double.tryParse(_wheelDiameter.text);
                        } catch (_) {
                          wheelDiameter = null;
                        }
                        try {
                          screwsInWheel = int.tryParse(_screwsInWheel.text);
                        } catch (_) {
                          screwsInWheel = null;
                        }
                        try {
                          axleLength = double.tryParse(_axleLength.text);
                        } catch (_) {
                          axleLength = null;
                        }

                        final currentUserId =
                            ref.read(authServiceProvider).currentUserId;
                        try {
                          if (isEditing) {
                            final id = widget.existingData!['id'] as String? ??
                                DateTime.now().millisecondsSinceEpoch.toString();
                            final data = {
                              'category': 'tractor',
                              'name': _name.text,
                              'userId': currentUserId,
                              'status': widget.existingData!['status'] as String? ??
                                  'vacant',
                              'wheelDiameter': wheelDiameter,
                              'screwsInWheel': screwsInWheel,
                              'axleLength': axleLength,
                            };
                            await ctrl.update(id, data);
                          } else {
                            final id =
                                DateTime.now().millisecondsSinceEpoch.toString();
                            final data = {
                              'id': id,
                              'category': 'tractor',
                              'name': _name.text,
                              'userId': currentUserId,
                              'status': 'vacant',
                              'wheelDiameter': wheelDiameter,
                              'screwsInWheel': screwsInWheel,
                              'axleLength': axleLength,
                            };
                            await ctrl.add(data);
                          }
                          if (!mounted) return;
                          navigator.pop(true);
                        } catch (e) {
                          String userMessage;
                          if (e is ApiException && e.body != null) {
                            try {
                              final parsed = json.decode(e.body!)
                                  as Map<String, dynamic>;
                              final msgs = <String>[];
                              parsed.forEach((k, v) {
                                if (v is List && v.isNotEmpty) {
                                  msgs.add('${k}: ${v.first}');
                                } else if (v is String) {
                                  msgs.add('${k}: $v');
                                } else {
                                  msgs.add('$k: ${v.toString()}');
                                }
                              });
                              userMessage = msgs.join(' • ');
                            } catch (_) {
                              userMessage = e.message;
                            }
                          } else {
                            userMessage = e.toString();
                          }

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(userMessage)),
                          );
                        }
                      },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      child: Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
