import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/equipment_providers.dart';
import 'package:simdaas/core/services/auth_service.dart';

class CreateEquipmentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingData;
  const CreateEquipmentScreen({super.key, this.existingData});

  @override
  ConsumerState<CreateEquipmentScreen> createState() =>
      _CreateEquipmentScreenState();
}

class _CreateEquipmentScreenState extends ConsumerState<CreateEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _category = 'tractor';
  final _mountingHeight = TextEditingController();
  final _lidarNozzleDistance = TextEditingController();
  final _ultrasonicDistance = TextEditingController();
  final _wheelDiameter = TextEditingController();
  final _screwsInWheel = TextEditingController();
  final _axleLength = TextEditingController();
  final _hingeToAxle = TextEditingController();
  final _hingeToNozzle = TextEditingController();
  final _hingeToControlUnit = TextEditingController();
  final _macAddress = TextEditingController();
  final _linkedSprayerId = TextEditingController();
  final _linkedTractorId = TextEditingController();
  final _controlUnitId = TextEditingController();
  String _sprayerType = 'lidar';

  @override
  Widget build(BuildContext context) {
    // if editing, prefill controllers
    final isEditing = widget.existingData != null;
    if (isEditing) {
      final ex = widget.existingData!;
      _category = ex['category'] as String? ?? _category;
      _name.text = ex['name'] as String? ?? '';
      if (ex['mountingHeight'] != null)
        _mountingHeight.text = '${ex['mountingHeight']}';
      if (ex['lidarNozzleDistance'] != null)
        _lidarNozzleDistance.text = '${ex['lidarNozzleDistance']}';
      if (ex['ultrasonicDistance'] != null)
        _ultrasonicDistance.text = '${ex['ultrasonicDistance']}';
      if (ex['wheelDiameter'] != null)
        _wheelDiameter.text = '${ex['wheelDiameter']}';
      if (ex['screwsInWheel'] != null)
        _screwsInWheel.text = '${ex['screwsInWheel']}';
      if (ex['axleLength'] != null) _axleLength.text = '${ex['axleLength']}';
      if (ex['hingeToAxle'] != null) _hingeToAxle.text = '${ex['hingeToAxle']}';
      if (ex['hingeToNozzle'] != null)
        _hingeToNozzle.text = '${ex['hingeToNozzle']}';
      if (ex['hingeToControlUnit'] != null)
        _hingeToControlUnit.text = '${ex['hingeToControlUnit']}';
      if (ex['macAddress'] != null)
        _macAddress.text = ex['macAddress'] as String? ?? '';
      if (ex['linkedSprayerId'] != null)
        _linkedSprayerId.text = ex['linkedSprayerId'] as String? ?? '';
      if (ex['linkedTractorId'] != null)
        _linkedTractorId.text = ex['linkedTractorId'] as String? ?? '';
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Create Equipment')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(children: [
            DropdownButtonFormField<String>(
              value: _category,
              items: const [
                DropdownMenuItem(value: 'tractor', child: Text('Tractor')),
                DropdownMenuItem(value: 'sprayer', child: Text('Sprayer')),
                DropdownMenuItem(
                    value: 'control_unit', child: Text('Control Unit')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'tractor'),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Equipment Name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter name' : null),
            const SizedBox(height: 12),
            if (_category == 'sprayer') ...[
              DropdownButtonFormField<String>(
                value: _sprayerType,
                items: const [
                  DropdownMenuItem(value: 'lidar', child: Text('Lidar')),
                  DropdownMenuItem(
                      value: 'ultrasonic', child: Text('Ultrasonic')),
                ],
                onChanged: (v) => setState(() => _sprayerType = v ?? 'lidar'),
                decoration:
                    const InputDecoration(labelText: 'Sprayer sensor type'),
              ),
              const SizedBox(height: 8),
              if (_sprayerType == 'lidar') ...[
                TextFormField(
                    controller: _mountingHeight,
                    decoration: const InputDecoration(
                        labelText: 'Mounting height of lidar (m)'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true)),
                TextFormField(
                    controller: _lidarNozzleDistance,
                    decoration: const InputDecoration(
                        labelText: 'Distance between lidar and nozzle (m)'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true)),
                TextFormField(
                    controller: _hingeToAxle,
                    decoration: const InputDecoration(
                        labelText: 'Distance between hinge point and axle (m)'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true)),
                TextFormField(
                    controller: _hingeToNozzle,
                    decoration: const InputDecoration(
                        labelText:
                            'Distance between hinge point and nozzle (m)'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true)),
                TextFormField(
                    controller: _hingeToControlUnit,
                    decoration: const InputDecoration(
                        labelText:
                            'Distance between hinge point and control unit mounting (m)'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true)),
              ] else ...[
                TextFormField(
                    controller: _ultrasonicDistance,
                    decoration: const InputDecoration(
                        labelText: 'Distance of sensor from center line (m)'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true)),
              ],
            ] else if (_category == 'tractor') ...[
              TextFormField(
                  controller: _wheelDiameter,
                  decoration:
                      const InputDecoration(labelText: 'Wheel diameter (m)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true)),
              TextFormField(
                  controller: _screwsInWheel,
                  decoration: const InputDecoration(
                      labelText: 'Number of screws in wheel'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: _axleLength,
                  decoration:
                      const InputDecoration(labelText: 'Axle length (m)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true)),
            ] else if (_category == 'control_unit') ...[
              TextFormField(
                  controller: _controlUnitId,
                  decoration:
                      const InputDecoration(labelText: 'Control unit ID'),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Enter control unit id'
                      : null),
              TextFormField(
                  controller: _macAddress,
                  decoration: const InputDecoration(labelText: 'MAC address'),
                  keyboardType: TextInputType.text),
              TextFormField(
                  controller: _linkedSprayerId,
                  decoration:
                      const InputDecoration(labelText: 'Linked sprayer ID'),
                  keyboardType: TextInputType.text),
              TextFormField(
                  controller: _linkedTractorId,
                  decoration:
                      const InputDecoration(labelText: 'Linked tractor ID'),
                  keyboardType: TextInputType.text),
            ] else if (_category == 'tractor')
              ...[],
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final ctrl = ref.read(equipmentControllerProvider);
                  double? mountingHeight;
                  double? lidarNozzleDistance;
                  double? wheelDiameter;
                  int? screwsInWheel;
                  double? ultrasonicDistance;
                  double? axleLength;
                  double? hingeToAxle;
                  double? hingeToNozzle;
                  double? hingeToControlUnit;
                  String? macAddress;
                  String? linkedSprayerId;
                  String? linkedTractorId;
                  try {
                    mountingHeight = double.tryParse(_mountingHeight.text);
                  } catch (_) {
                    mountingHeight = null;
                  }
                  try {
                    ultrasonicDistance =
                        double.tryParse(_ultrasonicDistance.text);
                  } catch (_) {
                    ultrasonicDistance = null;
                  }
                  try {
                    lidarNozzleDistance =
                        double.tryParse(_lidarNozzleDistance.text);
                  } catch (_) {
                    lidarNozzleDistance = null;
                  }
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
                  macAddress =
                      _macAddress.text.isEmpty ? null : _macAddress.text;
                  linkedSprayerId = _linkedSprayerId.text.isEmpty
                      ? null
                      : _linkedSprayerId.text;
                  linkedTractorId = _linkedTractorId.text.isEmpty
                      ? null
                      : _linkedTractorId.text;

                  final currentUserId =
                      ref.read(authServiceProvider).currentUserId;
                  if (isEditing) {
                    final id = widget.existingData!['id'] as String? ??
                        DateTime.now().millisecondsSinceEpoch.toString();
                    final data = {
                      'category': _category,
                      'name': _name.text,
                      'userId': currentUserId,
                      'status':
                          widget.existingData!['status'] as String? ?? 'vacant',
                      'controlUnitId': _controlUnitId.text.isEmpty
                          ? null
                          : _controlUnitId.text,
                      'mountingHeight': mountingHeight,
                      'lidarNozzleDistance': lidarNozzleDistance,
                      'ultrasonicDistance': ultrasonicDistance,
                      'wheelDiameter': wheelDiameter,
                      'screwsInWheel': screwsInWheel,
                      'axleLength': axleLength,
                      'hingeToAxle': hingeToAxle,
                      'hingeToNozzle': hingeToNozzle,
                      'hingeToControlUnit': hingeToControlUnit,
                      'macAddress': macAddress,
                      'linkedSprayerId': linkedSprayerId,
                      'linkedTractorId': linkedTractorId,
                    };
                    await ctrl.update(id, data);
                  } else {
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    final data = {
                      'id': id,
                      'category': _category,
                      'name': _name.text,
                      'userId': currentUserId,
                      'status': 'vacant',
                      'controlUnitId': _controlUnitId.text.isEmpty
                          ? null
                          : _controlUnitId.text,
                      'mountingHeight': mountingHeight,
                      'lidarNozzleDistance': lidarNozzleDistance,
                      'ultrasonicDistance': ultrasonicDistance,
                      'wheelDiameter': wheelDiameter,
                      'screwsInWheel': screwsInWheel,
                      'axleLength': axleLength,
                      'hingeToAxle': hingeToAxle,
                      'hingeToNozzle': hingeToNozzle,
                      'hingeToControlUnit': hingeToControlUnit,
                      'macAddress': macAddress,
                      'linkedSprayerId': linkedSprayerId,
                      'linkedTractorId': linkedTractorId,
                    };
                    await ctrl.add(data);
                  }
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('Save'))
          ]),
        ),
      ),
    );
  }
}
