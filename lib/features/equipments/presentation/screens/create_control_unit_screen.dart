import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/equipment_providers.dart';
import '../../../plot_mapping/presentation/providers/plot_providers.dart'
    as fm_providers;
import 'package:simdaas/core/services/auth_service.dart';
import 'dart:convert';
import 'package:simdaas/core/services/api_exception.dart';

class CreateControlUnitScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingData;
  final bool returnToAddPlot;
  const CreateControlUnitScreen({super.key, this.existingData, this.returnToAddPlot = false});

  @override
  ConsumerState<CreateControlUnitScreen> createState() =>
      _CreateControlUnitScreenState();
}

class _CreateControlUnitScreenState
    extends ConsumerState<CreateControlUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _controlUnitId = TextEditingController();
  final _macAddress = TextEditingController();
  String? _linkedSprayerId;
  String? _linkedTractorId;
  String? _linkedPlotId;
  final _lidarNozzleDistance = TextEditingController();
  final _mountHeightOfLidar = TextEditingController();
  final _ultrasonicDistance = TextEditingController();
  String _sensorType = 'lidar';
  // cache of existing MACs for quick uniqueness check (normalized)
  Set<String> _existingMacs = {};
  // flags to lock fields that were provided by QR scan
  bool _prefilledName = false;
  bool _prefilledControlUnitId = false;
  bool _prefilledMac = false;
  bool _prefilledLinkedSprayer = false;
  bool _prefilledLinkedTractor = false;
  bool _prefilledLinkedPlot = false;
  bool _prefilledSensorType = false;
  bool _prefilledLidarNozzle = false;
  bool _prefilledMountHeight = false;
  bool _prefilledUltrasonic = false;
  // whether we're editing an existing equipment (has server id)
  bool _isEditing = false;
  // Guard to ensure existingData is applied only once (avoid overwriting
  // user changes when the widget rebuilds while editing)
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _controlUnitId.dispose();
    _macAddress.dispose();
    // controllers removed for dropdowns
    _lidarNozzleDistance.dispose();
    _mountHeightOfLidar.dispose();
    _ultrasonicDistance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If this screen was opened as part of the "Add Plot -> Add Control Unit"
    // guided flow, intercept back navigation and return the user to the
    // plot-creation screen instead of the previous dashboard.
    return WillPopScope(
      onWillPop: () async {
        if (widget.returnToAddPlot) {
          // Replace this route with the map/plot add screen so Back goes to map.
          await Navigator.of(context).pushReplacementNamed('/map');
          return false;
        }
        return true;
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    // Prefill if existingData provided (e.g., from QR scan or editing an
    // existing equipment). Behavior differs for two cases:
    // - Editing existing equipment (_isEditing == true): lock only name and
    //   controlUnitId (these are primary/identity fields). Other fields will
    //   be populated but remain editable so the user can change them.
    // - QR scan / new prefill (not editing): preserve the original behavior
    //   where prefilled fields are locked individually.
    // Apply existingData only once to avoid overwriting any user changes
    // when the widget rebuilds while editing. This preserves new selections
    // the user makes in dropdowns during an edit session.
    final ex = widget.existingData;
    if (!_initialized && ex != null) {
      final m = ex;
      // mark editing when an 'id' is present in existing data
      if (m.containsKey('id') && (m['id']?.toString().isNotEmpty == true)) {
        _isEditing = true;
      }

      // Always populate controllers with existing values (if any)
      if (m.containsKey('name') && (m['name'] as String?)?.isNotEmpty == true) {
        _name.text = m['name'] as String;
      }

      // For display, prefer controlUnitId. If editing and controlUnitId is
      // missing, fall back to server `id` so the identifier is visible.
      if (m.containsKey('controlUnitId') &&
          (m['controlUnitId'] as String?)?.isNotEmpty == true) {
        _controlUnitId.text = m['controlUnitId'] as String;
      } else if (_isEditing && m.containsKey('id')) {
        _controlUnitId.text = m['id']?.toString() ?? '';
      }

      // When editing, only lock name and controlUnitId. For QR-prefill
      // (not editing) retain the previous per-field prefill locking.
      if (_isEditing) {
        if (_name.text.isNotEmpty) _prefilledName = true;
        if (_controlUnitId.text.isNotEmpty) _prefilledControlUnitId = true;
        // Populate other fields but don't set their _prefilled flags so they
        // remain editable.
        if (m.containsKey('macAddress') &&
            (m['macAddress'] as String?)?.isNotEmpty == true) {
          _macAddress.text = m['macAddress'] as String;
        }
        if (m.containsKey('linkedSprayerId') &&
            (m['linkedSprayerId'] as String?)?.isNotEmpty == true) {
          _linkedSprayerId = m['linkedSprayerId'] as String?;
        }
        if (m.containsKey('linkedPlotId') &&
            (m['linkedPlotId'] as String?)?.isNotEmpty == true) {
          _linkedPlotId = m['linkedPlotId'] as String?;
        }
        if (m.containsKey('linkedTractorId') &&
            (m['linkedTractorId'] as String?)?.isNotEmpty == true) {
          _linkedTractorId = m['linkedTractorId'] as String?;
        }
        if (m.containsKey('sensorType') &&
            (m['sensorType'] as String?)?.isNotEmpty == true) {
          _sensorType = m['sensorType'] as String;
        }
        if (m.containsKey('lidarNozzleDistance') &&
            m['lidarNozzleDistance'] != null) {
          _lidarNozzleDistance.text = m['lidarNozzleDistance'].toString();
        }
        if (m.containsKey('mountingHeight') && m['mountingHeight'] != null) {
          _mountHeightOfLidar.text = m['mountingHeight'].toString();
        }
        if (m.containsKey('ultrasonicDistance') &&
            m['ultrasonicDistance'] != null) {
          _ultrasonicDistance.text = m['ultrasonicDistance'].toString();
        }
      } else {
        // Not editing: treat values as QR-prefilled and lock fields that
        // were provided by the scanner (existing behavior).
        if (m.containsKey('name') &&
            (m['name'] as String?)?.isNotEmpty == true) {
          _name.text = m['name'] as String;
          _prefilledName = true;
        }
        if (m.containsKey('controlUnitId') &&
            (m['controlUnitId'] as String?)?.isNotEmpty == true) {
          _controlUnitId.text = m['controlUnitId'] as String;
          _prefilledControlUnitId = true;
        }
        if (m.containsKey('macAddress') &&
            (m['macAddress'] as String?)?.isNotEmpty == true) {
          _macAddress.text = m['macAddress'] as String;
          _prefilledMac = true;
        }
        if (m.containsKey('linkedSprayerId') &&
            (m['linkedSprayerId'] as String?)?.isNotEmpty == true) {
          _linkedSprayerId = m['linkedSprayerId'] as String?;
          _prefilledLinkedSprayer = true;
        }
        if (m.containsKey('linkedPlotId') &&
            (m['linkedPlotId'] as String?)?.isNotEmpty == true) {
          _linkedPlotId = m['linkedPlotId'] as String?;
          _prefilledLinkedPlot = true;
        }
        if (m.containsKey('linkedTractorId') &&
            (m['linkedTractorId'] as String?)?.isNotEmpty == true) {
          _linkedTractorId = m['linkedTractorId'] as String?;
          _prefilledLinkedTractor = true;
        }
        if (m.containsKey('sensorType') &&
            (m['sensorType'] as String?)?.isNotEmpty == true) {
          _sensorType = m['sensorType'] as String;
          _prefilledSensorType = true;
        }
        if (m.containsKey('lidarNozzleDistance') &&
            m['lidarNozzleDistance'] != null) {
          _lidarNozzleDistance.text = m['lidarNozzleDistance'].toString();
          _prefilledLidarNozzle = true;
        }
        if (m.containsKey('mountingHeight') && m['mountingHeight'] != null) {
          _mountHeightOfLidar.text = m['mountingHeight'].toString();
          _prefilledMountHeight = true;
        }
        if (m.containsKey('ultrasonicDistance') &&
            m['ultrasonicDistance'] != null) {
          _ultrasonicDistance.text = m['ultrasonicDistance'].toString();
          _prefilledUltrasonic = true;
        }
      }
      // Note: scanned owner info is ignored. The current authenticated user
      // will be used as the owner for created control units.
      _initialized = true;
    }
    // populate existing MACs cache for uniqueness checks
    try {
      final userId = ref.read(authServiceProvider).currentUserId ?? '';
      final cuAsync = ref.watch(controlUnitsProvider(userId));
      cuAsync.maybeWhen(data: (items) {
        _existingMacs = items
            .where((e) => (e.macAddress ?? '').isNotEmpty)
            .map((e) => e.macAddress!
                .replaceAll(RegExp(r'[^A-Fa-f0-9]'), '')
                .toLowerCase())
            .toSet();
      }, orElse: () {});
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'Edit Control Unit' : 'Add Control Unit')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          // ensure the scroll view moves above the keyboard
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !_prefilledName,
                  decoration:
                      const InputDecoration(labelText: 'Control Unit name'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _controlUnitId,
                  // control unit identifier should not be editable when editing
                  // an existing control unit (it's a primary identifier).
                  enabled: !_prefilledControlUnitId && !_isEditing,
                  decoration:
                      const InputDecoration(labelText: 'Control unit ID'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter control unit id' : null,
                ),
                const SizedBox(height: 8),
                // owner is not selectable; current user will be used
                const SizedBox(height: 8),
                TextFormField(
                  controller: _macAddress,
                  enabled: !_prefilledMac,
                  decoration: const InputDecoration(labelText: 'MAC address'),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Enter MAC address';
                    // normalize: remove separators and lowercase
                    final norm = val.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '').toLowerCase();
                    if (norm.isEmpty) return 'Enter valid MAC address';
                    // when we have cached existing MACs, ensure uniqueness
                    if (_existingMacs.isNotEmpty) {
                      final own = widget.existingData?['macAddress']?.toString().replaceAll(RegExp(r'[^A-Fa-f0-9]'), '').toLowerCase();
                      for (final e in _existingMacs) {
                        if (own != null && own == e && e == norm) continue; // ignore own
                        if (e == norm) return 'MAC address already exists';
                        if (e.contains(norm) || norm.contains(e)) return 'MAC address too similar to existing device';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Sprayer & Tractor dropdowns
                const SizedBox(height: 8),
                Consumer(builder: (context, ref, _) {
                  final userId =
                    ref.read(authServiceProvider).currentUserId ?? '';
                  final eqAsync = ref.watch(sprayersProvider(userId));
                  return eqAsync.when(
                      data: (items) {
                        final sprayers = items
                            .where((e) => e.category == 'sprayer')
                            .toList();
                        return DropdownButtonFormField<String?>(
                          value: _linkedSprayerId,
                          decoration: const InputDecoration(
                              labelText: 'Linked sprayer'),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('None')),
                            ...sprayers.map((e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(
                                    '${e.name}${e.controlUnitId != null ? ' (${e.controlUnitId})' : ''}')))
                          ],
                      onChanged: _prefilledLinkedSprayer
                        ? null
                        : (v) => setState(() => _linkedSprayerId = v),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Select a linked sprayer';
                        return null;
                      },
                          disabledHint: _prefilledLinkedSprayer &&
                                  _linkedSprayerId != null
                              ? () {
                                  final found = sprayers.isNotEmpty
                                      ? sprayers.firstWhere(
                                          (s) => s.id == _linkedSprayerId,
                                          orElse: () => sprayers.first)
                                      : null;
                                  final display = found != null
                                      ? found.name
                                      : _linkedSprayerId;
                                  return Text('Linked: ${display ?? ''}');
                                }()
                              : null,
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, st) => const SizedBox());
                }),
                const SizedBox(height: 8),
                Consumer(builder: (context, ref, _) {
                  final userId =
                      ref.read(authServiceProvider).currentUserId ?? '';
                  final eqAsync = ref.watch(tractorsProvider(userId));
                  return eqAsync.when(
                      data: (items) {
                        final tractors = items
                            .where((e) => e.category == 'tractor')
                            .toList();
                        final dropdown = DropdownButtonFormField<String?>(
                          value: _linkedTractorId,
                          decoration: const InputDecoration(
                              labelText: 'Linked tractor'),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('None')),
                            ...tractors.map((e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(
                                    '${e.name}${e.controlUnitId != null ? ' (${e.controlUnitId})' : ''}')))
                          ],
                          onChanged: _prefilledLinkedTractor
                              ? null
                              : (v) => setState(() => _linkedTractorId = v),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Select a linked tractor';
                            return null;
                          },
                          disabledHint: _prefilledLinkedTractor &&
                                  _linkedTractorId != null
                              ? () {
                                  final found = tractors.isNotEmpty
                                      ? tractors.firstWhere(
                                          (s) => s.id == _linkedTractorId,
                                          orElse: () => tractors.first)
                                      : null;
                                  final display = found != null
                                      ? found.name
                                      : _linkedTractorId;
                                  return Text('Linked: ${display ?? ''}');
                                }()
                              : null,
                        );

                        return Row(
                          children: [
                            Expanded(child: dropdown),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Add tractor',
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () async {
                                // Navigate to add tractor screen and refresh tractors list on return
                                await Navigator.of(context)
                                    .pushNamed('/create_tractor');
                                // Invalidate provider so the new tractor appears in dropdown
                                ref.invalidate(tractorsProvider(userId));
                              },
                            ),
                          ],
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, st) => const SizedBox());
                }),
                const SizedBox(height: 8),
                // Plot dropdown
                Consumer(builder: (context, ref, _) {
                  final userId =
                      ref.read(authServiceProvider).currentUserId ?? '';
                  final plotsAsync =
                      ref.watch(fm_providers.plotsListProvider(userId));
                  return plotsAsync.when(
                      data: (items) {
                        return DropdownButtonFormField<String?>(
                          value: _linkedPlotId,
                          decoration:
                              const InputDecoration(labelText: 'Default plot'),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('None')),
                            ...items.map((p) => DropdownMenuItem(
                                value: p.id, child: Text(p.name)))
                          ],
                          onChanged: _prefilledLinkedPlot
                              ? null
                              : (v) => setState(() => _linkedPlotId = v),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Select a default plot';
                            return null;
                          },
                          disabledHint:
                              _prefilledLinkedPlot && _linkedPlotId != null
                                  ? () {
                                      final found = items.isNotEmpty
                                          ? items.firstWhere(
                                              (s) => s.id == _linkedPlotId,
                                              orElse: () => items.first)
                                          : null;
                                      final display = found != null
                                          ? found.name
                                          : _linkedPlotId;
                                      return Text('Linked: ${display ?? ''}');
                                    }()
                                  : null,
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, st) => const SizedBox());
                }),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _sensorType,
                  decoration: const InputDecoration(labelText: 'Sensor type'),
                  items: const [
                    DropdownMenuItem(value: 'lidar', child: Text('LIDAR')),
                    DropdownMenuItem(
                        value: 'ultrasonic', child: Text('Ultrasonic')),
                  ],
                  onChanged: _prefilledSensorType
                      ? null
                      : (v) {
                          final nv = v ?? 'lidar';
                          setState(() {
                            _sensorType = nv;
                            // Clear the hidden fields when switching
                            if (_sensorType == 'lidar') {
                              _ultrasonicDistance.clear();
                            } else {
                              _mountHeightOfLidar.clear();
                              _lidarNozzleDistance.clear();
                            }
                          });
                        },
                  validator: (v) => (v == null || v.isEmpty) ? 'Select sensor type' : null,
                  disabledHint: _prefilledSensorType
                      ? Text(_sensorType.toUpperCase())
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lidarNozzleDistance,
                  enabled: !_prefilledLidarNozzle,
                  decoration: const InputDecoration(
                    labelText: 'Distance b/w sensor and nozzle center (m)'),
                  keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter distance' : null,
                ),
                if (_sensorType == 'lidar') ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _mountHeightOfLidar,
                    enabled: !_prefilledMountHeight,
                    decoration: const InputDecoration(
                        labelText: 'Mount height of LIDAR (m)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    // mount height is allowed to be empty per requirements
                    validator: (v) => null,
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ultrasonicDistance,
                    enabled: !_prefilledUltrasonic,
                    decoration: const InputDecoration(
                        labelText:
                            'Distance of US sensor from center line (m)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    // ultrasonic distance is allowed to be empty per requirements
                    validator: (v) => null,
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final ctrl = ref.read(equipmentControllerProvider);
                    final navigator = Navigator.of(context);
                    final currentUserId =
                        ref.read(authServiceProvider).currentUserId;

                    // Build payload. For updates we will reuse the existing id.
                    final data = {
                      'category': 'control_unit',
                      'name': _name.text,
                      // always assign to current authenticated user
                      'userId': currentUserId,
                      'status': 'vacant',
                      'controlUnitId': _controlUnitId.text.isEmpty
                          ? null
                          : _controlUnitId.text,
                      'macAddress':
                          _macAddress.text.isEmpty ? null : _macAddress.text,
                      'linkedSprayerId': _linkedSprayerId,
                      'linkedTractorId': _linkedTractorId,
                      'linkedPlotId': _linkedPlotId,
                      'lidarNozzleDistance': _lidarNozzleDistance.text.isEmpty
                          ? null
                          : double.tryParse(_lidarNozzleDistance.text),
                      'mountingHeight': _mountHeightOfLidar.text.isEmpty
                          ? null
                          : double.tryParse(_mountHeightOfLidar.text),
                      'ultrasonicDistance': _ultrasonicDistance.text.isEmpty
                          ? null
                          : double.tryParse(_ultrasonicDistance.text),
                    };

                    try {
                      if (_isEditing &&
                          (widget.existingData?.containsKey('id') == true)) {
                        final existingId =
                            widget.existingData!['id']?.toString();
                        if (existingId != null && existingId.isNotEmpty) {
                          await ctrl.update(existingId, data);
                        } else {
                          // fallback to add if id not available
                          final id = DateTime.now()
                              .millisecondsSinceEpoch
                              .toString();
                          data['id'] = id;
                          await ctrl.add(data);
                        }
                      } else {
                        final id = DateTime.now()
                            .millisecondsSinceEpoch
                            .toString();
                        data['id'] = id;
                        await ctrl.add(data);
                      }

                      if (!mounted) return;
                      // signal success to caller so list screens can react
                      navigator.pop(true);
                    } catch (e) {
                      // parse ApiException body for user-friendly message
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
