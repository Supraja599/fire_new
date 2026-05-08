import os

base_dir = r"c:\Users\A\AndroidStudioProjects\Fire_New\lib"

modules = [
    {"folder": "heat_detector", "prefix": "HeatDetector", "name": "Heat Detector"},
    {"folder": "co_detector", "prefix": "CODetector", "name": "CO Detector"},
    {"folder": "fire_door", "prefix": "FireDoor", "name": "Fire Door"},
]

for mod in modules:
    target_dir = os.path.join(base_dir, mod["folder"])
    if not os.path.exists(target_dir):
        continue
        
    for root, _, files in os.walk(target_dir):
        for file in files:
            if file.endswith(".dart"):
                file_path = os.path.join(root, file)
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()
                
                # Replace class names
                content = content.replace("AmbulanceMaintenancePage", f"{mod['prefix']}MaintenancePage")
                content = content.replace("AmbulanceAlertsPage", f"{mod['prefix']}AlertsPage")
                content = content.replace("AmbulancePlantHealthPage", f"{mod['prefix']}PlantHealthPage")
                content = content.replace("AmbulanceReportsPage", f"{mod['prefix']}ReportsPage")
                content = content.replace("AmbulanceChecklistPage", f"{mod['prefix']}ChecklistPage")
                content = content.replace("AmbulanceScanPage", f"{mod['prefix']}ScanPage")
                
                # Replace UI text "Ambulance" that might have been missed
                content = content.replace('Text("Ambulance"', f'Text("{mod["name"]}"')
                content = content.replace('Text("Ambulance ', f'Text("{mod["name"]} ')
                
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(content)

print("Fixed class names in 3 new modules.")
