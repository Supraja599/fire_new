import os
import re
import glob

def inject_master_dashboards():
    lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
    dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
    
    # Include special sprinklers dashboard
    sprinkler = os.path.join(lib_dir, 'splinkers', 'sprinkler.dart')
    if os.path.exists(sprinkler):
        dashboards.append(sprinkler)
        
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
    
    print(f"Resolving variables and deploying to {len(dashboards)} Master Consoles...")
    
    success_count = 0
    for db_path in dashboards:
        if not os.path.exists(db_path):
            continue
            
        rel_path = os.path.relpath(db_path, lib_dir)
        
        # Read file
        with open(db_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            
        # 1. Skip if already injected
        if "MASTER EXECUTIVE RADIAL TELEMETRY BANNER" in content:
            print(f"[SKIP] {rel_path} already consolidated.")
            continue
            
        # 2. Find image asset mapping
        parent_dir = os.path.basename(os.path.dirname(db_path))
        if "sprinkler.dart" in db_path:
            parent_dir = "splinkers"
        asset_path = mappings.get(parent_dir, "assets/extinguisher.png")
        tag_name = f"hero_image_{asset_path}"
        
        # 3. Resolve Local Active Count variable name from State declarations
        # Look for "int deviceCount =", "int active =", "int activeUnits ="
        var_name = "active" # Default fallback
        
        # Try to find inside the class body
        matches = re.findall(r'int\s+(activeUnits|deviceCount|activeLoops|activeCount|active)\s*=', content)
        if matches:
            var_name = matches[0]
        else:
            # Fallback search
            if "deviceCount" in content: var_name = "deviceCount"
            elif "activeUnits" in content: var_name = "activeUnits"
            elif "activeLoops" in content: var_name = "activeLoops"
            elif "activeCount" in content: var_name = "activeCount"
            else: var_name = "active"
            
        # Special root dashboard override handler
        if rel_path == "dashboard.dart":
            asset_path = "assets/extinguisher.png"
            tag_name = "hero_image_assets/extinguisher.png"
            var_name = "active"
            
        # 4. Build ultimate Master Banner Payload
        master_banner = f"""            // 🏆 MASTER EXECUTIVE RADIAL TELEMETRY BANNER
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 🚀 TOP TIER: Massive Radial Dial & Upgraded 3D Device Asset
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. LEFT: Gorgeous Circular Radial Indicator
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100, // Upgraded size for dominance
                            height: 100, // Upgraded size for dominance
                            child: CircularProgressIndicator(
                              value: isLoading ? 0.0 : (health / 100.0),
                              strokeWidth: 9.5,
                              backgroundColor: Colors.grey.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isLoading 
                                  ? Colors.grey 
                                  : (health >= 85 
                                      ? const Color(0xFF1E8E3E) 
                                      : (health >= 60 ? const Color(0xFFFF8F00) : const Color(0xFFD50000))),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLoading ? "--" : "${{health}}%",
                                style: TextStyle(
                                  fontSize: 23, // Huge executive look
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[850],
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const Text(
                                "HEALTH",
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: Colors.grey,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                      // 2. RIGHT: The HUGE, BEAUTIFUL Device Asset Image!
                      Hero(
                        tag: "{tag_name}",
                        child: Image.asset(
                          "{asset_path}",
                          width: 115, // Exploded size!
                          height: 115, // Exploded size!
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 16),
                  // 📝 BOTTOM TIER: System Diagnostic Summary
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BlinkingActiveBadge(),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoading
                                  ? "Accessing systems..."
                                  : (health >= 85 
                                      ? "Optimal Status Standing" 
                                      : (health >= 60 ? "Advisory Maintenance Required" : "Critical System Attention Required")),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: isLoading 
                                    ? Colors.grey 
                                    : (health >= 85 
                                        ? const Color(0xFF1E8E3E) 
                                        : (health >= 60 ? const Color(0xFFFF8F00) : const Color(0xFFD50000))),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              isLoading
                                  ? "Decrypting real-time sensor telemetry streams..."
                                  : "Successfully validating ${var_name} active units currently operational out of ${{total}} deployed devices.",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey[600],
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),"""

        # 5. Inject imports
        if "blinking_badge.dart" not in content:
            content = "import 'package:fire_new/widgets/blinking_badge.dart';\n" + content
            
        # 6. Inject Console right below Minimal Header's anchor: "const SizedBox(height: 5),"
        target_anchor = "const SizedBox(height: 5),"
        if target_anchor in content:
            # Replace only the FIRST occurrence, which is the header trailing spacer
            content = content.replace(target_anchor, f"{target_anchor}\n{master_banner}", 1)
        else:
            # Alternative search
            alt_anchor = "HealthScoreWidget(health: health),\n                ],\n              ),\n            ),"
            if alt_anchor in content:
                content = content.replace(alt_anchor, f"{alt_anchor}\n{master_banner}", 1)
            else:
                print(f"[FAIL] Anchor mismatch for {rel_path}")
                continue
                
        # Write new content
        with open(db_path, 'w', encoding='utf-8') as f:
            f.write(content)
            
        print(f"[OK] Master Console Deployed to {rel_path} (Variable: {var_name})")
        success_count += 1
        
    print(f"\nFINISHED: Deployed {success_count} Ultimate consolidated Master Consoles successfully!")

inject_master_dashboards()
