import os
import re

def process_scan_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    if 'selectedEquipment: item' in content:
        print(f"  [Skip Scan] {file_path} already updated.")
        return
    
    # Capture navigation calls in scan.dart or inspection.dart
    # Pattern looks for: MaterialPageRoute(builder: (_) => [const] XXXChecklistPage())
    pattern = r'(MaterialPageRoute\s*\(\s*builder\s*:\s*\(_\)\s*=>\s*)(const\s+)?(\w+ChecklistPage)\s*\(\s*\)'
    new_content, count = re.subn(pattern, r'\1\3(selectedEquipment: item)', content)
    
    if count > 0:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"  [Updated Scan] {file_path} ({count} match(es))")
    else:
        print(f"  [Warn Scan] No navigation match found in {file_path}")

def process_checklist_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'GEOLOCATION PROXIMITY VERIFICATION' in content:
        print(f"  [Skip Checklist] {file_path} already updated.")
        return

    # 1. Inject Local Service Import
    if "import '../services/location_service.dart';" not in content:
        content = re.sub(
            r"(import 'package:flutter/material\.dart';)",
            r"\1\nimport '../services/location_service.dart';",
            content,
            count=1
        )

    # 2. Get the Checklist Class Name
    class_match = re.search(r'class\s+(\w+ChecklistPage)\s+extends\s+StatefulWidget', content)
    if not class_match:
        print(f"  [Error Checklist] Could not determine class name in {file_path}")
        return
    
    class_name = class_match.group(1)
    
    # 3. Replace Constructor to support 'selectedEquipment'
    # This regex matches class header and replaces the default const constructor
    old_declaration = rf"class\s+{class_name}\s+extends\s+StatefulWidget\s*\{{\s*(const\s+{class_name}\(\s*{{\s*super\.key\s*}}\s*\);)?"
    new_declaration = f"class {class_name} extends StatefulWidget {{\n  final Map<String, dynamic>? selectedEquipment;\n  const {class_name}({{super.key, this.selectedEquipment}});"
    
    content = re.sub(old_declaration, new_declaration, content, count=1)

    # 4. Auto-inject Controller Prefills inside initState
    if 'widget.selectedEquipment != null' not in content:
        controller_name = None
        if 'equipmentController' in content:
            controller_name = 'equipmentController'
        elif 'equipmentIdController' in content:
            controller_name = 'equipmentIdController'
            
        if controller_name:
            init_state_block = f"""  @override
  void initState() {{ 
    super.initState(); 
    _load(); 
    if (widget.selectedEquipment != null) {{
      {controller_name}.text = widget.selectedEquipment!["sos_code"]?.toString() ?? 
                               widget.selectedEquipment!["equipment_id"]?.toString() ?? 
                               widget.selectedEquipment!["id"]?.toString() ?? "";
    }}
  }}"""
            # Handle replacements based on existing common patterns
            if 'void initState() { super.initState(); _load(); }' in content:
                content = content.replace('void initState() { super.initState(); _load(); }', init_state_block)
            elif 'void initState() { super.initState(); _loadChecklist(); }' in content:
                init_state_block_alt = init_state_block.replace('_load()', '_loadChecklist()')
                content = content.replace('void initState() { super.initState(); _loadChecklist(); }', init_state_block_alt)
            elif 'void initState() {\n    super.initState();\n    _loadChecklist();\n  }' in content:
                init_state_block_multi = f"""  @override
  void initState() {{
    super.initState();
    _loadChecklist();
    if (widget.selectedEquipment != null) {{
      {controller_name}.text = widget.selectedEquipment!["sos_code"]?.toString() ?? 
                               widget.selectedEquipment!["equipment_id"]?.toString() ?? 
                               widget.selectedEquipment!["id"]?.toString() ?? "";
    }}
  }}"""
                content = content.replace('void initState() {\n    super.initState();\n    _loadChecklist();\n  }', init_state_block_multi)

    # 5. Construct and Inject the Core Proximity Lock
    save_block = r"""    // --- GEOLOCATION PROXIMITY VERIFICATION BLOCK ---
    if (widget.selectedEquipment != null &&
        (widget.selectedEquipment!["latitude"] != null || widget.selectedEquipment!["lat"] != null) &&
        (widget.selectedEquipment!["longitude"] != null || widget.selectedEquipment!["lng"] != null)) {
      
      double? lat = double.tryParse((widget.selectedEquipment!["latitude"] ?? widget.selectedEquipment!["lat"]).toString());
      double? lng = double.tryParse((widget.selectedEquipment!["longitude"] ?? widget.selectedEquipment!["lng"]).toString());
      
      if (lat != null && lng != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(width: 20),
                Text("Verifying physical presence..."),
              ],
            ),
          ),
        );

        final result = await LocationService.verifyProximity(
          targetLat: lat,
          targetLng: lng,
          maxAllowedDistanceMeters: 100.0,
        );

        if (mounted) Navigator.pop(context);

        if (!result.success) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text("Location Check Required"),
                content: Text(result.errorMessage ?? "Unknown Location Error"),
                actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
              ),
            );
          }
          return;
        }

        if (!result.withinRange) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Action Restricted", style: TextStyle(color: Colors.red)),
                  ],
                ),
                content: Text("⚠️ Location Verification Failed!\n\nYou are " + result.distanceMeters!.toStringAsFixed(1) + " meters away from the asset location.\n\nYou must stand within 100 meters of this equipment to perform inspection."),
                actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
              ),
            );
          }
          return;
        }
      }
    }
    // --- END OF VERIFICATION BLOCK ---
"""

    # Find any format of the save method (void _save() async {, etc.)
    save_pattern = r'((void|Future<void>)\s+(_save|_saveOffline|_saveInspection)\(\)\s*async\s*\{)'
    new_content, count = re.subn(save_pattern, r'\1\n' + save_block, content)
    
    if count > 0:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"  [Updated Checklist] {file_path}")
    else:
        print(f"  [Error Checklist] Could NOT find save method in {file_path}")

def run():
    base_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
    # Skip generic non-module core dirs
    skip_dirs = {'widgets', 'icons', 'services'}
    
    for folder in os.listdir(base_dir):
        dir_path = os.path.join(base_dir, folder)
        if os.path.isdir(dir_path) and folder not in skip_dirs:
            # Find navigation/scanning file
            nav_file = os.path.join(dir_path, 'scan.dart')
            if not os.path.exists(nav_file):
                nav_file = os.path.join(dir_path, 'inspection.dart')
                
            chk_file = os.path.join(dir_path, 'checklist.dart')
            
            # Only act if a checklist exists for this module
            if os.path.exists(chk_file):
                print(f"Processing module: {folder}...")
                if os.path.exists(nav_file):
                    process_scan_file(nav_file)
                else:
                    print(f"  [Warn] No scan/inspection file found in {folder}")
                
                process_checklist_file(chk_file)

if __name__ == "__main__":
    run()
