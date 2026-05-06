import os
import re

base_dir = r"c:\Users\A\AndroidStudioProjects\Fire_New\lib"

# Mapping of folder name to new API Module ID
module_ids = {
    "first_aid": 45,
    "emergency_shower": 47,
    "eye_wash": 46,
    "spill_kits": 48,
    "ppe_cabinets": 49,
    "fire_blankets": 41,
    "co2_system": 42, # Assuming Suppression System
}

for folder, new_id in module_ids.items():
    api_service_path = os.path.join(base_dir, folder, "services", "api_service.dart")
    
    if os.path.exists(api_service_path):
        with open(api_service_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Use regex to find and replace the moduleId
        content = re.sub(r'static const int moduleId = \d+;', f'static const int moduleId = {new_id};', content)
        
        with open(api_service_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Updated {folder} to moduleId {new_id}")
    else:
        print(f"File not found: {api_service_path}")

print("Module IDs updated successfully!")
