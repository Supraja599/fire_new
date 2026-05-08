import os
import shutil

base_dir = r"c:\Users\A\AndroidStudioProjects\Fire_New\lib"
source_dir = os.path.join(base_dir, "ambulance")

modules = [
    {"folder": "heat_detector", "class_prefix": "HeatDetector", "name": "Heat Detector", "id": 37, "code": "heat_detector"},
    {"folder": "co_detector", "class_prefix": "CODetector", "name": "CO Detector", "id": 40, "code": "co_detector"},
    {"folder": "fire_door", "class_prefix": "FireDoor", "name": "Fire Door", "id": 43, "code": "fire_door"},
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
                content = content.replace("AmbulanceApiService", f"{mod['class_prefix']}ApiService")
                content = content.replace("AmbulanceDashboard", f"{mod['class_prefix']}Dashboard")
                content = content.replace("AmbulanceScanPage", f"{mod['class_prefix']}ScanPage")
                content = content.replace("AmbulanceChecklistPage", f"{mod['class_prefix']}ChecklistPage")
                content = content.replace("AmbulancePlantHealthPage", f"{mod['class_prefix']}PlantHealthPage")
                content = content.replace("AmbulanceAlertsPage", f"{mod['class_prefix']}AlertsPage")
                content = content.replace("AmbulanceMaintaincePage", f"{mod['class_prefix']}MaintaincePage")
                content = content.replace("AmbulanceReportsPage", f"{mod['class_prefix']}ReportsPage")
                
                content = content.replace("ambulance", mod["folder"])
                content = content.replace("Ambulance ", f"{mod['name']} ")
                # content = content.replace("Ambulance", f"{mod['name']}") # This is risky, but Ambulance name is unique enough here
                
                # Update module ID and code
                if file == "api_service.dart":
                    content = content.replace("moduleId = 58", f"moduleId = {mod['id']}")
                    content = content.replace('moduleCode = "ambulance"', f'moduleCode = "{mod["code"]}"')
                
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(content)
                
print("Added 3 missing modules successfully!")
