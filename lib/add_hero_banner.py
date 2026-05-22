import os
import re
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

mappings = {
    "splinkers": "assets/sprinkler.png",
    "hydrant": "assets/firehydrant.png",
    "hosereel": "assets/hosereel.png",
    "alarm_panel": "assets/alarm_panel.png",
    "smoke_detector": "assets/smoke_detector.png",
    "fire_trolley": "assets/fire_trolley.png",
    "emergency_exits": "assets/emergency_exit.png",
    "emergency_lighting": "assets/emergency_lighting.png",
    "pa_system": "assets/pa_system.png",
    "wind_sock": "assets/wind_sock.png",
    "scba_units": "assets/scba_unit.png",
    "ambulance": "assets/ambulance.png",
    "first_aid": "assets/first_aid.png",
    "emergency_shower": "assets/emergency_shower.png",
    "eye_wash": "assets/eye_wash.png",
    "spill_kits": "assets/spill_kits.png",
    "chemical_shower": "assets/chemical_shower.png",
    "ppe_cabinets": "assets/ppe_cabinets.png",
    "co2_system": "assets/co2_system.png",
    "signage": "assets/signage.png",
    "emergency_comm": "assets/emergency_comm.png",
    "fire_blankets": "assets/fire_blankets.png",
    "muster_points": "assets/muster_points.png",
    "heat_detector": "assets/heat_detector.png",
    "co_detector": "assets/co_detector.png",
    "fire_door": "assets/fire_door.png",
}

def build_banner_code(image_path):
    return f"""            // Elite Module Hero Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD50000).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "SYSTEM ACTIVE",
                            style: TextStyle(
                              color: Color(0xFFD50000),
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Asset Management",
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Manage inspections, check real-time status, and ensure regulatory readiness.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Hero(
                    tag: "hero_image_{image_path}",
                    child: Image.asset(
                      "{image_path}",
                      width: 75,
                      height: 75,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),"""

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
    
    # Skip root dashboard, we'll edit that in a specialized way
    if os.path.abspath(path) == os.path.abspath(os.path.join(lib_dir, 'dashboard.dart')):
        continue
        
    # Determine directory name
    parent_dir = os.path.basename(os.path.dirname(path))
    if "sprinkler.dart" in path:
        parent_dir = "splinkers"
        
    image_path = mappings.get(parent_dir, "assets/extinguisher.png")
    
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Insert right below the header
    old_marker = "const SizedBox(height: 5),"
    new_banner = build_banner_code(image_path)
    
    # Check if already injected to prevent double injection
    if "Elite Module Hero Banner" in content:
        continue
        
    if old_marker in content:
        content = content.replace(old_marker, new_banner, 1)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Injected Elite Hero Banners into {count} module dashboards!")
