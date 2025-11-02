import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/equipment_providers.dart';
import 'package:simdaas/core/services/auth_service.dart';

class CreateSprayerScreen extends ConsumerStatefulWidget {
  const CreateSprayerScreen({super.key});

  @override
  ConsumerState<CreateSprayerScreen> createState() =>
      _CreateSprayerScreenState();
}

class _CreateSprayerScreenState extends ConsumerState<CreateSprayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _wheelDiameter = TextEditingController();
  final _screwsInWheel = TextEditingController();
  final _hingeToAxle = TextEditingController();
  final _hingeToNozzle = TextEditingController();
  final _hingeToControlUnit = TextEditingController();
  final _axleLength = TextEditingController();
  final _nozzleCount = TextEditingController();
  final _tankCapacity = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _wheelDiameter.dispose();
    _screwsInWheel.dispose();
    _hingeToAxle.dispose();
    _hingeToNozzle.dispose();
    _hingeToControlUnit.dispose();
    _axleLength.dispose();
    _nozzleCount.dispose();
    _tankCapacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Sprayer')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Sprayer name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
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
                decoration: const InputDecoration(labelText: 'Axle length (m)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nozzleCount,
                decoration: const InputDecoration(labelText: 'Number of nozzles'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tankCapacity,
                decoration: const InputDecoration(labelText: 'Tank capacity (L)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hingeToAxle,
                decoration: const InputDecoration(
                    labelText: 'Distance between hinge point and axle (m)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hingeToNozzle,
                decoration: const InputDecoration(
                    labelText: 'Distance between hinge point and nozzle (m)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hingeToControlUnit,
                decoration: const InputDecoration(
                    labelText:
                        'Distance between hinge point and control unit mounting (m)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final ctrl = ref.read(equipmentControllerProvider);
                  final navigator = Navigator.of(context);
                  double? wheelDiameter;
                  int? screwsInWheel;
                  double? hingeToAxle;
                  double? hingeToNozzle;
                  double? hingeToControlUnit;
                  double? axleLength;
                  int? nozzleCount;
                  double? tankCapacity;
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
                    hingeToAxle = double.tryParse(_hingeToAxle.text);
                  } catch (_) {
                    hingeToAxle = null;
                  }
                  try {
                    hingeToNozzle = double.tryParse(_hingeToNozzle.text);
                  } catch (_) {
                    hingeToNozzle = null;
                  }
                  try {
                    hingeToControlUnit =
                        double.tryParse(_hingeToControlUnit.text);
                  } catch (_) {
                    hingeToControlUnit = null;
                  }

                  try {
                    axleLength = double.tryParse(_axleLength.text);
                  } catch (_) {
                    axleLength = null;
                  }
                  try {
                    nozzleCount = int.tryParse(_nozzleCount.text);
                  } catch (_) {
                    nozzleCount = null;
                  }
                  try {
                    tankCapacity = double.tryParse(_tankCapacity.text);
                  } catch (_) {
                    tankCapacity = null;
                  }

                  final currentUserId =
                      ref.read(authServiceProvider).currentUserId;
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  final data = {
                    'id': id,
                    'category': 'sprayer',
                    'name': _name.text,
                    'userId': currentUserId,
                    'status': 'vacant',
                    'wheelDiameter': wheelDiameter,
                    'screwsInWheel': screwsInWheel,
                    'hingeToAxle': hingeToAxle,
                    'hingeToNozzle': hingeToNozzle,
                    'hingeToControlUnit': hingeToControlUnit,
                    'axleLength': axleLength,
                    'nozzleCount': nozzleCount,
                    'tankCapacity': tankCapacity,
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
