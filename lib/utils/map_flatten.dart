import 'package:flutter/material.dart';

/// Recursively flattens a nested Map into rows for display.
/// Nested Maps are expanded into their own labelled rows.
List<Widget> buildDetailRows(Map<dynamic, dynamic> data) {
  final Map<String, String> flat = {};

  void flatten(Map<dynamic, dynamic> map, [String prefix = '']) {
    map.forEach((key, value) {
      final k = prefix.isEmpty ? key.toString() : '${prefix}_$key';
      if (value is Map) {
        flatten(value, k);
      } else if (value != null && value is! List) {
        flat[k] = value.toString();
      }
    });
  }

  flatten(data);

  return flat.entries.map((e) {
    final label = e.key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              e.value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }).toList();
}
