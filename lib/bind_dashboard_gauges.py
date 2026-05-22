import os
import glob
import re

def deploy_dashboard_gauge():
    root_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
    # Find all sub-module dashboard files
    dashboards = glob.glob(os.path.join(root_dir, '**', 'dashboard.dart'), recursive=True)
    # Also include special sprinklers dashboard
    sprinkler = os.path.join(root_dir, 'splinkers', 'sprinkler.dart')
    if os.path.exists(sprinkler):
        dashboards.append(sprinkler)
        
    print(f"Found {len(dashboards)} dashboard candidates for Gauge deployment!")
    
    success_count = 0
    
    for db_path in dashboards:
        rel_path = os.path.relpath(db_path, root_dir)
        if rel_path == "dashboard.dart":
            continue # Already manually upgraded root dashboard
            
        with open(db_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            
        # 1. Identify active item variable dynamically from LinearProgressIndicator!
        var_match = re.search(r'value\s*:\s*total\s*>\s*0\s*\?\s*\(\s*([A-Za-z0-9_]+)\s*/\s*total\s*\)', content)
        if not var_match:
            # Try alternative pattern
            var_match = re.search(r'value\s*:\s*total\s*>\s*0\s*\?\s*([A-Za-z0-9_]+)\s*/\s*total', content)
            
        if not var_match:
            print(f"[SKIP] {rel_path}: Could not resolve active variable.")
            continue
            
        active_var = var_match.group(1)
        
        # Check if already injected
        if "EXECUTIVE CIRCULAR RADIAL GAUGE BANNER" in content:
            print(f"[SKIP] {rel_path} already has Gauge.")
            continue
            
        # 2. Prepare the high-end radial gauge code block
        gauge_code = f"""            const SizedBox(height: 4),
            
            // 🎛️ EXECUTIVE CIRCULAR RADIAL GAUGE BANNER
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.08),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // LEFT SIDE: Gorgeous Circular Gauge Core
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          value: isLoading ? 0.0 : (health / 100.0),
                          strokeWidth: 8,
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
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey[850],
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            "HEALTH",
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Colors.grey,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  const SizedBox(width: 18),
                  // RIGHT SIDE: Detailed Insights
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SYSTEM READINESS",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isLoading
                              ? "Analyzing systems..."
                              : (health >= 85 
                                  ? "Optimal Status" 
                                  : (health >= 60 ? "Service Advisory" : "Critical System Alert")),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: isLoading 
                                ? Colors.grey 
                                : (health >= 85 
                                    ? const Color(0xFF1E8E3E) 
                                    : (health >= 60 ? const Color(0xFFFF8F00) : const Color(0xFFD50000))),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Divider(height: 4, thickness: 0.8),
                        ),
                        Text(
                          isLoading
                              ? "Synchronizing real-time sensor logs..."
                              : "Currently validating {active_var} operational safety units out of ${{total}} fully deployed objects.",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 6),"""

        target_str = "            const SizedBox(height: 10),"
        alt_target = "            const SizedBox(height: 15),"
        
        split_tag = "fit: BoxFit.contain,\n                    ),\n                  ),\n                ],\n              ),\n            ),\n            const SizedBox(height: 10),"
        split_tag_alt = "fit: BoxFit.contain,\n                    ),\n                  ),\n                ],\n              ),\n            ),\n            const SizedBox(height: 15),"

        new_content = content
        if split_tag in content:
            new_val = split_tag.replace(target_str, gauge_code)
            new_content = content.replace(split_tag, new_val)
        elif split_tag_alt in content:
            new_val = split_tag_alt.replace(alt_target, gauge_code)
            new_content = content.replace(split_tag_alt, new_val)
        else:
            wider_target = "fit: BoxFit.contain,\n                    ),\n                  ),\n                ],\n              ),\n            ),\n"
            if wider_target in content:
                m = re.search(re.escape(wider_target) + r'\s*const\s+SizedBox\(height:\s*\d+\),', content)
                if m:
                    matched_str = m.group(0)
                    new_content = content.replace(matched_str, wider_target + gauge_code)
                else:
                    new_content = content.replace(wider_target, wider_target + gauge_code)
            else:
                print(f"[FAIL] visual anchor not found for {rel_path}")
                continue
                
        with open(db_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
            
        print(f"[OK] Deployed Gauge to {rel_path} (Variable: {active_var})")
        success_count += 1
        
    print(f"\nDONE: Successfully deployed {success_count} Gauges.")

deploy_dashboard_gauge()
