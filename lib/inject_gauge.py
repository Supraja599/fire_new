import os
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'

def get_module_name(folder):
    parts = folder.split('_')
    return ' '.join(p.capitalize() for p in parts)

count = 0
for root, _, files in os.walk(lib_dir):
    if root == lib_dir: continue
    folder = os.path.basename(root)
    if folder in ['icons', 'services', 'widgets']: continue
    
    for f in files:
        if f == 'dashboard.dart' or f == 'sprinkler.dart':
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
                
            original_content = content
            
            # 1. Inject Map<String, dynamic>? summaryData;
            if 'Map<String, dynamic>? summaryData;' not in content:
                content = re.sub(r'(bool isLoading = true;)', r'\1\n  Map<String, dynamic>? summaryData;', content)
                
            # 2. Inject summaryData = s; inside setState
            if 'summaryData = s;' not in content:
                content = re.sub(r'(health = ApiService\.calculateHealth\(s\);)', r'summaryData = s;\n          \1', content)
                
            # 3. Add Import
            if "import 'package:fire_new/widgets/safety_gauge_widget.dart';" not in content:
                content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:fire_new/widgets/safety_gauge_widget.dart';")
                
            # 4. Inject SafetyGaugeWidget above // Action Grid
            module_name = get_module_name(folder)
            
            gauge_code = f"""
            // Safety Gauge
            SafetyGaugeWidget(
              active: summaryData?["active_units"] ?? summaryData?["active"] ?? 0,
              expired: summaryData?["expired"] ?? 0,
              needsService: summaryData?["needs_service"] ?? summaryData?["needs-service"] ?? 0,
              inspection: summaryData?["needs_inspection"] ?? summaryData?["inspection"] ?? 0,
              health: health,
              moduleName: "{module_name}",
            ),
            """
            
            if 'SafetyGaugeWidget(' not in content:
                content = content.replace('// Action Grid', gauge_code + '\n            // Action Grid')
                
            if content != original_content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(content)
                count += 1
                print(f"Updated {folder}/{f}")

print(f"Total dashboards updated: {count}")
