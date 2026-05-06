import os
import re

modules = [
    ("ambulance", "AmbulanceApiService"),
    ("emergency_exits", "EmergencyExitsApiService"),
    ("emergency_lighting", "EmergencyLightingApiService"),
    ("pa_system", "PASystemApiService"),
    ("scba_units", "SCBAUnitsApiService"),
    ("wind_sock", "WindSockApiService")
]

base_dir = r"c:\Users\A\AndroidStudioProjects\Fire_New\lib"

func_code = """
  Future<Map<String, dynamic>?> getEquipmentByQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/equipment/$trimmed"),
        headers: headers,
      );

      if (response.statusCode == 404) {
        return LocalDB.findModuleEquipment(
          moduleCode: moduleCode,
          query: trimmed,
        );
      }

      final decoded = _decodeBody(response);
      if (decoded is Map<String, dynamic>) {
        final itemModuleCode = decoded["module_code"]?.toString();
        if (itemModuleCode != null && itemModuleCode != moduleCode) {
          return null; 
        }
        return decoded;
      }
      return null;
    } catch (_) {
      return LocalDB.findModuleEquipment(
        moduleCode: moduleCode,
        query: trimmed,
      );
    }
  }
"""

for mod, api_class in modules:
    api_file = os.path.join(base_dir, mod, "services", "api_service.dart")
    scan_file = os.path.join(base_dir, mod, "scan.dart")
    
    # 1. Update api_service.dart
    if os.path.exists(api_file):
        with open(api_file, "r", encoding="utf-8") as f:
            content = f.read()
        
        if "getEquipmentByQuery" not in content:
            # Insert before the last closing brace
            last_brace_idx = content.rfind("}")
            if last_brace_idx != -1:
                content = content[:last_brace_idx] + func_code + "\n}\n"
                with open(api_file, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"Updated API Service: {api_file}")

    # 2. Update scan.dart
    if os.path.exists(scan_file):
        with open(scan_file, "r", encoding="utf-8") as f:
            content = f.read()
            
        old_line = f"LocalDB.findModuleEquipment(moduleCode: {api_class}.moduleCode, query: code)"
        old_line2 = f"LocalDB.findModuleEquipment(moduleCode: {api_class}.moduleCode, query: code);"
        
        if old_line in content:
            content = content.replace(old_line, "api.getEquipmentByQuery(code)")
            with open(scan_file, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"Updated Scan: {scan_file}")
