import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/equipment_providers.dart';
import 'package:simdaas/core/services/auth_service.dart';

class CreateTractorScreen extends ConsumerStatefulWidget {
  const CreateTractorScreen({super.key});

  @override
  ConsumerState<CreateTractorScreen> createState() =>
      _CreateTractorScreenState();
}

class _CreateTractorScreenState extends ConsumerState<CreateTractorScreen> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Tractor')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tractor name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wheelDiameter,
                decoration:
                    const InputDecoration(labelText: 'Wheel diameter (m)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _screwsInWheel,
                decoration: const InputDecoration(
                    labelText: 'Number of screws in wheel'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _axleLength,
                decoration:
                    const InputDecoration(labelText: 'Axle length (m)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              const Spacer(),
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
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
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
                  if (!mounted) return;
                  navigator.pop();
                },
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
