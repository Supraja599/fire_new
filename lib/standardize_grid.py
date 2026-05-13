import os
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'

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
                
            if folder == 'fire_extinguisher': continue # Keep as reference
            
            # Find the children block of GridView.count
            grid_match = re.search(r'children:\s*\[([\s\S]*?)\]\s*,?\s*\n\s*\)', content)
            if not grid_match:
                print(f"No grid found in {folder}")
                continue
                
            grid_block = grid_match.group(1)
            
            # Extract all ActionCards
            cards = re.findall(r'_ActionCard\(\s*"([^"]+)"\s*,\s*[^,]+,\s*[^,]+,\s*(const\s+[A-Za-z0-9_]+\(\))\s*(?:,\s*"[^"]+")?\s*\)', grid_block)
            
            page_map = {}
            for label, page_code in cards:
                l = label.lower()
                if l == 'checklist' or l == 'analytics': page_map['Analytics'] = page_code
                elif l == 'scan' or l == 'inspection': page_map['Inspection'] = page_code
                elif l == 'maintenance': page_map['Maintenance'] = page_code
                elif l == 'alerts': page_map['Alerts'] = page_code
                elif l == 'plant health': page_map['Plant Health'] = page_code
                elif l == 'reports': page_map['Reports'] = page_code
            
            # Build exactly matching Fire Extinguisher grid
            new_children = f"""
                      _ActionCard("Analytics", Icons.bar_chart_rounded, const Color(0xFFD32F2F), {page_map.get('Analytics', 'const SizedBox()')}, "Trends"),
                      _ActionCard("Inspection", Icons.fact_check_rounded, const Color(0xFFD32F2F), {page_map.get('Inspection', 'const SizedBox()')}, "Scan"),
                      _ActionCard("Maintenance", Icons.construction_rounded, const Color(0xFFD32F2F), {page_map.get('Maintenance', 'const SizedBox()')}, "Service"),
                      _ActionCard("Alerts", Icons.emergency_rounded, const Color(0xFFD32F2F), {page_map.get('Alerts', 'const SizedBox()')}, "Critical"),
                      _ActionCard("Plant Health", Icons.monitor_heart_rounded, const Color(0xFFD32F2F), {page_map.get('Plant Health', 'const SizedBox()')}, "Score"),
                      _ActionCard("Reports", Icons.history_edu_rounded, const Color(0xFFD32F2F), {page_map.get('Reports', 'const SizedBox()')}, "Logs"),
"""
            
            new_content = content[:grid_match.start(1)] + new_children + content[grid_match.end(1):]
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                count += 1
                print(f"Standardized grid in {folder}/{f}")

print(f"Total dashboards standardized: {count}")
