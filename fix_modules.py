import os
import shutil

base_dir = r"c:\Users\A\AndroidStudioProjects\Fire_New\lib"
source_dir = os.path.join(base_dir, "ambulance")

modules = [
    {"folder": "first_aid", "class_prefix": "FirstAid", "name": "First Aid", "id": 101},
    {"folder": "emergency_shower", "class_prefix": "EmergencyShower", "name": "Emergency Shower", "id": 102},
    {"folder": "eye_wash", "class_prefix": "EyeWash", "name": "Eye Wash", "id": 103},
    {"folder": "spill_kits", "class_prefix": "SpillKits", "name": "Spill Kits", "id": 104},
    {"folder": "chemical_shower", "class_prefix": "ChemicalShower", "name": "Chemical Shower", "id": 105},
    {"folder": "ppe_cabinets", "class_prefix": "PPECabinets", "name": "PPE Cabinets", "id": 106},
    {"folder": "co2_system", "class_prefix": "CO2System", "name": "CO2 System", "id": 107},
    {"folder": "signage", "class_prefix": "Signage", "name": "Signage", "id": 108},
    {"folder": "emergency_comm", "class_prefix": "EmergencyComm", "name": "Emergency Comm", "id": 109},
    {"folder": "fire_blankets", "class_prefix": "FireBlankets", "name": "Fire Blankets", "id": 110},
    {"folder": "muster_points", "class_prefix": "MusterPoints", "name": "Muster Points", "id": 111},
]

for mod in modules:
    target_dir = os.path.join(base_dir, mod["folder"])
    
    # 1. Copy directory
    if os.path.exists(target_dir):
        shutil.rmtree(target_dir)
    shutil.copytree(source_dir, target_dir)
    
    # 2. Process all dart files in the target directory
    for root, _, files in os.walk(target_dir):
        for file in files:
            if file.endswith(".dart"):
                file_path = os.path.join(root, file)
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()
                
                # Replace strings
                # 1. Safely replace class names and variable names
                content = content.replace("Ambulance", mod['class_prefix'])
                content = content.replace("ambulance", mod["folder"])
                
                # 2. Fix UI display text
                content = content.replace(f'"{mod["class_prefix"]} ', f'"{mod["name"]} ')
                content = content.replace(f"'{mod['class_prefix']} ", f"'{mod['name']} ")
                content = content.replace(f"{mod['class_prefix']} Dashboard", f"{mod['name']} Dashboard")
                content = content.replace(f"{mod['class_prefix']} Checklist", f"{mod['name']} Checklist")
                content = content.replace(f"{mod['class_prefix']} Scan", f"{mod['name']} Scan")
                content = content.replace(f"{mod['class_prefix']} Maintenance", f"{mod['name']} Maintenance")
                content = content.replace(f"{mod['class_prefix']} Plant Health", f"{mod['name']} Plant Health")
                content = content.replace(f"{mod['class_prefix']} Reports", f"{mod['name']} Reports")
                content = content.replace(f"{mod['class_prefix']} Alerts", f"{mod['name']} Alerts")
                
                # Update module ID
                if file == "api_service.dart":
                    content = content.replace("moduleId = 57", f"moduleId = {mod['id']}")
                
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(content)

print("Regenerated 11 new modules successfully without spaces in class names!")
