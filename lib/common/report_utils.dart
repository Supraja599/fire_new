/// Utility functions for report pages

/// Ensures that the selected value for a DropdownButton is present in the list of items.
/// If the selected value is null or not in the list, the first item from [items] is returned.
/// This prevents runtime errors caused by mismatched Dropdown values.
T? ensureDropdownValue<T>(T? selected, List<T> items) {
  if (selected != null && items.contains(selected)) {
    return selected;
  }
  return items.isNotEmpty ? items.first : null;
}

String _firstNonEmptyValue(Map<String, dynamic> item, List<String> keys, {String fallback = "-"}) {
  for (final key in keys) {
    final value = item[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != "null") {
      return text;
    }
  }
  return fallback;
}

String reportEquipmentId(Map<String, dynamic> item, {String fallback = "-"}) {
  return _firstNonEmptyValue(
    item,
    ["sos_code", "equipment_id", "serial_number", "asset_code", "tag_number", "id"],
    fallback: fallback,
  );
}

String reportLocation(Map<String, dynamic> item, {String fallback = "-"}) {
  return _firstNonEmptyValue(
    item,
    [
      "location_name",
      "building_name",
      "zone_name",
      "area_name",
      "area",
      "location",
      "site_name",
      "department_name",
      "plant_name",
    ],
    fallback: fallback,
  );
}

String reportPreviousInspection(Map<String, dynamic> item, {String fallback = "-"}) {
  return _firstNonEmptyValue(
    item,
    [
      "last_inspection_date",
      "last_service_date",
      "last_service",
      "last_inspected",
      "last_inspected_at",
      "inspected_date",
      "inspection_date",
      "updated_at",
      "previous_inspection",
      "previous_inspection_date",
      "last_checked_at",
      "last_maintenance_date",
    ],
    fallback: fallback,
  );
}

String reportNextInspection(Map<String, dynamic> item, {String fallback = "-"}) {
  return _firstNonEmptyValue(
    item,
    [
      "next_inspection_due",
      "next_due_date",
      "next_service_date",
      "due_date",
      "inspection_due_date",
      "expiry_date",
    ],
    fallback: fallback,
  );
}

String reportStatus(Map<String, dynamic> item, {String fallback = "-"}) {
  return _firstNonEmptyValue(
    item,
    ["status_label", "status_bucket", "operational_status", "status", "condition"],
    fallback: fallback,
  );
}

String _normalizeStatus(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll("_", " ")
      .replaceAll("-", " ")
      .replaceAll(RegExp(r"\s+"), " ");
}

bool matchesReportStatus(Map<String, dynamic> item, String statusLabel) {
  final normalizedTarget = _normalizeStatus(statusLabel);
  final normalizedItem = _normalizeStatus(reportStatus(item, fallback: ""));

  if (normalizedItem.isEmpty) return false;
  if (normalizedItem == normalizedTarget) return true;

  const aliases = {
    "needs service": {"need service", "needs service", "needs servicing"},
    "due inspection": {"due inspection", "inspection due"},
    "active": {"active", "ok", "operational", "upcoming"},
    "expired": {"expired", "overdue"},
  };

  final targetAliases = aliases[normalizedTarget];
  if (targetAliases == null) {
    return normalizedItem.contains(normalizedTarget);
  }

  return targetAliases.contains(normalizedItem);
}
