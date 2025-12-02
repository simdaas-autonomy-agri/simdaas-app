import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:simdaas/core/services/api_exception.dart';

String _stripExceptionPrefix(String s) {
  // Remove common prefixes like "Exception: " or "ApiException: "
  return s.replaceFirst(RegExp(r'^.*?:\s*'), '');
}

String extractErrorMessage(Object? error) {
  if (error == null) return 'Unknown error';
  try {
    if (error is ApiException) {
      // Prefer server 'body' if available, otherwise fall back to message.
      final raw = (error.body != null && error.body!.isNotEmpty)
          ? error.body!
          : error.message;

      // Try direct JSON parse first
      if (raw.isNotEmpty) {
        try {
          final parsed = json.decode(raw);
          if (parsed is String) return parsed;
          if (parsed is Map) {
            if (parsed.containsKey('detail')) return parsed['detail'].toString();
            final parts = <String>[];
            parsed.forEach((k, v) {
              if (v is List && v.isNotEmpty) {
                parts.addAll(v.map((e) => '$k: ${e.toString()}'));
              } else if (v != null) {
                parts.add('$k: ${v.toString()}');
              }
            });
            if (parts.isNotEmpty) return parts.join('; ');
          }
        } catch (_) {
          // If direct parse fails, try to extract JSON substring (e.g., "body: {...}")
          try {
            final start = raw.indexOf('{');
            final end = raw.lastIndexOf('}');
            if (start != -1 && end != -1 && end > start) {
              final candidate = raw.substring(start, end + 1);
              final parsed = json.decode(candidate);
              if (parsed is String) return parsed;
              if (parsed is Map) {
                if (parsed.containsKey('detail')) return parsed['detail'].toString();
                final parts = <String>[];
                parsed.forEach((k, v) {
                  if (v is List && v.isNotEmpty) {
                    parts.addAll(v.map((e) => '$k: ${e.toString()}'));
                  } else if (v != null) {
                    parts.add('$k: ${v.toString()}');
                  }
                });
                if (parts.isNotEmpty) return parts.join('; ');
              }
            }
          } catch (_) {}
        }

        // If no JSON extracted, return the raw message without prefixes
        return _stripExceptionPrefix(raw);
      }

      return 'An error occurred';
    }

    // Generic Exception or other
    final s = error.toString();

    // If the string contains a JSON body (common when code throws with resp.body),
    // try to extract and parse that JSON to pull user-friendly messages.
    try {
      final start = s.indexOf('{');
      final end = s.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        final candidate = s.substring(start, end + 1);
        final parsed = json.decode(candidate);
        if (parsed is String) return parsed;
        if (parsed is Map) {
          if (parsed.containsKey('detail')) return parsed['detail'].toString();
          final parts = <String>[];
          parsed.forEach((k, v) {
            if (v is List && v.isNotEmpty) {
              parts.addAll(v.map((e) => e.toString()));
            } else if (v != null) {
              parts.add(v.toString());
            }
          });
          if (parts.isNotEmpty) return parts.join('; ');
        }
      }
    } catch (_) {
      // fallthrough to stripping message below
    }

    return _stripExceptionPrefix(s);
  } catch (_) {
    return 'An error occurred';
  }
}

void showPolishedError(BuildContext context, Object? error,
    {String? fallback}) {
  final msg = extractErrorMessage(error);
  // Replace separator with newlines for SnackBar display so each field/error
  // appears on its own line.
  final display = (msg.isNotEmpty) ? msg.replaceAll('; ', '\n') : (fallback ?? 'An error occurred');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(display)));
}
