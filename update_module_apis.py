import os

lib_dir = r"c:\Users\A\AndroidStudioProjects\Fire_New\lib"

# Skip base apiservice
skip_files = [
    os.path.join(lib_dir, r"services\apiservice.dart")
]

new_methods = """
  Future<List<Map<String, dynamic>>> getActive() => _getAndCacheList("$baseUrl/equipment?module_id=$moduleId&status=active", "active");
  Future<List<Map<String, dynamic>>> getNeedsService() => _getAndCacheList("$baseUrl/equipment?module_id=$moduleId&status=needs-service", "needs_service");
  Future<List<Map<String, dynamic>>> getExpired() => _getAndCacheList("$baseUrl/equipment?module_id=$moduleId&status=expired", "expired");
  Future<List<Map<String, dynamic>>> getDueInspection() => _getAndCacheList("$baseUrl/equipment?module_id=$moduleId&status=due-inspection", "due_inspection");
  Future<List<Map<String, dynamic>>> getUpcoming() => _getAndCacheList("$baseUrl/equipment?module_id=$moduleId&status=upcoming", "upcoming");
  Future<Map<String, dynamic>> getPlantHealth() => _getAndCacheMap("$baseUrl/modules/$moduleId/plant-health", "plant_health");
  
  Future<List<Map<String, dynamic>>> getInspectionReports({required String fromDate, required String toDate}) {
    return _getAndCacheList("$baseUrl/reports/inspections?date_from=$fromDate&date_to=$toDate&module_id=$moduleId", "inspection_reports");
  }

  Future<List<Map<String, dynamic>>> getEquipmentStatusReport() {
    return _getAndCacheList("$baseUrl/reports/equipment-status?module_id=$moduleId", "equipment_status_report");
  }
"""

sync_update = """    await Future.wait([
      getSummary(),
      getEquipmentList(),
      getChecklist(),
      getAlerts(),
      getActive(),
      getNeedsService(),
      getExpired(),
      getDueInspection(),
      getUpcoming(),
      getPlantHealth()
    ]);"""

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if "api" in file.lower() and file.endswith(".dart"):
            file_path = os.path.join(root, file)
            if file_path in skip_files:
                continue
            
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            if "Future<List<Map<String, dynamic>>> getActive()" in content:
                continue
            
            # Insert before the last closing brace
            last_brace = content.rfind("}")
            if last_brace != -1:
                # Find the syncModuleData method to update it
                sync_pos = content.find("Future<void> syncModuleData()")
                if sync_pos != -1:
                    sync_end = content.find("]", sync_pos)
                    if sync_end != -1:
                        # Find the start of the list [
                        sync_start = content.find("[", sync_pos)
                        content = content[:sync_start] + sync_update[sync_update.find("["):] + content[sync_end+2:]
                
                # Re-find last brace as content changed
                last_brace = content.rfind("}")
                content = content[:last_brace] + new_methods + "\n" + content[last_brace:]
                
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"Updated {file_path}")
