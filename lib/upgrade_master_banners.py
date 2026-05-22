import os
import glob
import re

def deploy_master_consolidated_banner():
    root_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
    dashboards = glob.glob(os.path.join(root_dir, '**', 'dashboard.dart'), recursive=True)
    
    sprinkler = os.path.join(root_dir, 'sprinklers', 'sprinkler.dart')
    if os.path.exists(sprinkler):
        dashboards.append(sprinkler)
        
    print(f"Found {len(dashboards)} candidate dashboards for Master Banner Upgrade.")
    
    success_count = 0
    
    for db_path in dashboards:
        rel_path = os.path.relpath(db_path, root_dir)
        if rel_path == "dashboard.dart":
            continue # Already upgraded root manually
            
        with open(db_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            
        # 1. Extract the Asset Image and Hero Tag
        hero_match = re.search(r'Hero\(\s*tag:\s*"([^"]+)"[^G]+child:\s*Image\.asset\(\s*"([^"]+)"', content, re.DOTALL)
        if not hero_match:
            # Try alternative capture
            hero_match = re.search(r'tag:\s*"([^"]+)"[\s\S]*?Image\.asset\(\s*"([^"]+)"', content)
            
        if not hero_match:
            print(f"[SKIP] {rel_path}: Failed to parse Hero asset image data.")
            continue
            
        tag_name = hero_match.group(1)
        image_path = hero_match.group(2)
        
        # 2. Locate the Active Variable Name from the previously injected banner or fallback
        var_match = re.search(r'Currently\s+validating\s+([A-Za-z0-9_]+)\s+operational\s+safety\s+units', content)
        if not var_match:
            # Try fallback to the progress logic
            var_match = re.search(r'value\s*:\s*total\s*>\s*0\s*\?\s*\(\s*([A-Za-z0-9_]+)\s*/\s*total\s*\)', content)
            
        if not var_match:
            print(f"[SKIP] {rel_path}: Failed to resolve active telemetry variable.")
            continue
            
        active_var = var_match.group(1)
        
        # 3. Check if already Consolidated
        if "MASTER EXECUTIVE RADIAL TELEMETRY BANNER" in content:
            print(f"[SKIP] {rel_path} is already upgraded.")
            continue
            
        # 4. Generate the Unified Master Console code
        master_banner_code = f"""            // 🏆 MASTER EXECUTIVE RADIAL TELEMETRY BANNER
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
                          "{image_path}",
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
                                  : "Successfully validating ${active_var} active units currently operational out of ${{total}} deployed devices.",
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

        # 5. Define removal patterns
        # We need to delete the Elite Hero Banner AND the Gauge Banner.
        # Start Anchor: "Container(\n              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),\n              padding: const EdgeInsets.all(18),"
        # End Anchor: Ending of previously injected gauge card block
        
        # Perform broad replacement by slicing from the start of the Elite card Container to the end of the old Gauge Card.
        # Pattern: Starts from // Elite Module Hero Banner OR Container (margin: 20,12, pad 18) and ends right before "// Action Grid"
        
        match_pattern = r'(/\*.*?\*/|//[^\n]*)*\s*Container\(\s*margin:\s*const\s+EdgeInsets\.symmetric\(horizontal:\s*20,\s*vertical:\s*12\),\s*padding:\s*const\s+EdgeInsets\.all\(18\),.*?EXECUTIVE CIRCULAR RADIAL GAUGE BANNER.*?\)\s*,\s*\n\s*const\s+SizedBox\(height:\s*\d+\),?\s*\n'
        
        if re.search(match_pattern, content, re.DOTALL):
            new_content = re.sub(match_pattern, master_banner_code, content, flags=re.DOTALL)
        else:
            # Fallback targeted slicing:
            # Find start index of "            // Elite Module Hero Banner" or the next "Container("
            start_idx = content.find("// Elite Module Hero Banner")
            if start_idx == -1:
                # Look for specific top card signature
                start_idx = content.find("Container(\n              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),\n              padding: const EdgeInsets.all(18),")
                
            end_idx = content.find("// Action Grid")
            if end_idx == -1:
                end_idx = content.find("Builder(\n              builder: (context) {")
                
            if start_idx != -1 and end_idx != -1:
                # Construct the sliced payload
                new_content = content[:start_idx] + master_banner_code + "\n            " + content[end_idx:]
            else:
                print(f"[FAIL] {rel_path}: AST could not cleanly map coordinates.")
                continue
                
        with open(db_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
            
        print(f"[OK] Upgraded {rel_path} to Ultimate Master Console (Bound: {active_var})")
        success_count += 1
        
    print(f"\nDONE: Successfully rolled out {success_count} Ultimate Master Consoles!")

deploy_master_consolidated_banner()
