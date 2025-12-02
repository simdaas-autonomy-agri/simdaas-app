String canonicalizeMac(String input) {
  final s = input.trim().toLowerCase();
  // Remove any non-hex characters
  final hex = s.replaceAll(RegExp(r'[^0-9a-f]'), '');
  if (hex.length != 12) {
    // If it doesn't look like a MAC after stripping, fall back to trimmed lower
    return s;
  }
  final parts = List<String>.generate(6, (i) => hex.substring(i * 2, i * 2 + 2));
  return parts.join(':');
}

String extractDeviceId(dynamic cu) {
  if (cu == null) return '';
  // If it's a map-like object, try common keys
  try {
    if (cu is Map) {
      final keys = ['mac', 'macAddress', 'mac_address', 'controlUnitId', 'control_unit_id', 'id'];
      for (final k in keys) {
        if (cu.containsKey(k) && cu[k] != null) {
          final v = cu[k].toString();
          if (v.trim().isNotEmpty) return canonicalizeMac(v);
        }
      }
    }
  } catch (_) {}

  // Try calling toJson() if available (models often expose this)
  try {
    final dyn = cu as dynamic;
    final m = dyn.toJson?.call();
    if (m is Map) {
      final keys = ['mac', 'macAddress', 'mac_address', 'controlUnitId', 'control_unit_id', 'id'];
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) {
          final v = m[k].toString();
          if (v.trim().isNotEmpty) return canonicalizeMac(v);
        }
      }
    }
  } catch (_) {}

  // Try dynamic getters as a last resort
  try {
    final dyn = cu as dynamic;
    final candidates = ['mac', 'macAddress', 'controlUnitId', 'id'];
    for (final name in candidates) {
      try {
        final val = dyn?.__getProperty?.call(name) ?? null;
        if (val != null) {
          final s = val.toString();
          if (s.trim().isNotEmpty) return canonicalizeMac(s);
        }
      } catch (_) {
        try {
          final val2 = dyn
              .toString()
              .contains(name) ? dyn : null; // cheap check - ignore
        } catch (_) {}
      }
    }
  } catch (_) {}

  return '';
}

/// Safely stringify an object for logging/UI. Attempts `toJson()` -> JSON,
/// falls back to `toString()` and catches any JS interop types that may throw.
String safeStringify(dynamic v) {
  try {
    if (v == null) return 'null';
    if (v is String) return v;
    if (v is Map || v is Iterable) return v.toString();
    try {
      final dyn = v as dynamic;
      final m = dyn.toJson?.call();
      if (m is Map || m is List) return m.toString();
    } catch (_) {}
    return v.toString();
  } catch (_) {
    return '<unstringifiable>';
  }
}
