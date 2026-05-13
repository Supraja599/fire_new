import shutil
import os

mappings = {
    r"C:\Users\A\.gemini\antigravity\brain\9452b9d0-1448-41cd-8583-e700ad911d14\extinguisher_1778591140091.png": r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\extinguisher.png",
    r"C:\Users\A\.gemini\antigravity\brain\9452b9d0-1448-41cd-8583-e700ad911d14\sprinkler_1778591162074.png": r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\sprinkler.png",
    r"C:\Users\A\.gemini\antigravity\brain\21c8b9f8-08c3-4bf3-a39d-b49d4e07d3e4\fire_hydrant_1778647420426.png": r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\firehydrant.png",
    r"C:\Users\A\.gemini\antigravity\brain\21c8b9f8-08c3-4bf3-a39d-b49d4e07d3e4\alarm_panel_1778647397005.png": r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\alarm_panel.png",
    r"C:\Users\A\.gemini\antigravity\brain\21c8b9f8-08c3-4bf3-a39d-b49d4e07d3e4\emergency_exits_1778647437084.png": r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\emergency_exit.png",
    r"C:\Users\A\.gemini\antigravity\brain\21c8b9f8-08c3-4bf3-a39d-b49d4e07d3e4\emergency_light_1778648217540.png": r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\emergency_lighting.png",
    r"C:\Users\A\.gemini\antigravity\brain\21c8b9f8-08c3-4bf3-a39d-b49d4e07d3e4\pa_system_1778647454270.png": r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\pa_system.png",
    r"C:\Users\A\.gemini\antigravity\brain\21c8b9f8-08c3-4bf3-a39d-b49d4e07d3e4\wind_sock_1778648179088.png": r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\wind_sock.png",
    r"C:\Users\A\.gemini\antigravity\brain\21c8b9f8-08c3-4bf3-a39d-b49d4e07d3e4\scba_unit_1778648196093.png": r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\scba_unit.png",
    r"C:\Users\A\.gemini\antigravity\brain\9452b9d0-1448-41cd-8583-e700ad911d14\ambulance_1778591193822.png": r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\ambulance.png",
    r"C:\Users\A\.gemini\antigravity\brain\9452b9d0-1448-41cd-8583-e700ad911d14\first_aid_1778591175808.png": r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\first_aid.png",
}

for src, dst in mappings.items():
    if not os.path.exists(src):
        print(f"ERROR: Source file does not exist: {src}")
        continue
    
    # Backup existing just in case
    if os.path.exists(dst):
        backup_path = dst.replace(".png", "_old.png")
        if not os.path.exists(backup_path):
            try:
                shutil.copy2(dst, backup_path)
                print(f"Backed up existing: {os.path.basename(dst)} to {os.path.basename(backup_path)}")
            except Exception as e:
                print(f"Failed to backup {dst}: {e}")
    
    try:
        shutil.copy2(src, dst)
        print(f"Successfully restored premium {os.path.basename(dst)} from brain cache!")
    except Exception as e:
        print(f"Failed to copy {src} to {dst}: {e}")

print("\nAsset recovery process complete! Please trigger a 'flutter clean' and 'flutter run' if running to load the new physical assets.")
