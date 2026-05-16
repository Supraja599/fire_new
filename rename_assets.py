import os
import glob
import shutil

assets_dir = 'c:/Users/A/AndroidStudioProjects/Fire_New/assets'

mappings = {
    'alarm_panel_premium_*.png': 'alarm_panel.png',
    'ambulance_premium_*.png': 'ambulance.png',
    'co2_system_premium_*.png': 'co2_system.png',
    'emergency_comm_premium_*.png': 'emergency_comm.png',
    'emergency_shower_premium_*.png': 'emergency_shower.png',
    'fire_blanket_premium_*.png': 'fire_blanket.png',
    'fire_door_premium_*.png': 'fire_door.png',
    'first_aid_premium_*.png': 'first_aid.png',
    'heat_detector_premium_*.png': 'heat_detector.png',
    'muster_point_premium_*.png': 'muster_point.png',
    'pa_system_premium_*.png': 'pa_system.png',
    'ppe_cabinet_premium_*.png': 'ppe_cabinets.png',
    'scba_unit_premium_*.png': 'scba_unit.png',
    'signage_premium_*.png': 'signage.png',
    'smoke_detector_premium_*.png': 'smoke_detector.png',
    'spill_kit_premium_*.png': 'spill_kits.png',
    'wind_sock_premium_*.png': 'wind_sock.png'
}

for pattern, target in mappings.items():
    matches = glob.glob(os.path.join(assets_dir, pattern))
    if matches:
        # Sort by name (usually contains timestamp) and pick the latest if multiple
        matches.sort()
        source = matches[-1]
        target_path = os.path.join(assets_dir, target)
        print(f"Renaming {source} to {target_path}")
        shutil.copy2(source, target_path) # Using copy instead of move to be safe
