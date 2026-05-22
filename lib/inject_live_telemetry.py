import os
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

# The hyper-premium telemetry console containing the Dynamic Linear Gauge
live_gauge_code = """                        const BlinkingActiveBadge(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Device Health",
                              style: TextStyle(
                                color: Colors.grey[900],
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              isLoading ? "--" : "${active}/${total} Active",
                              style: const TextStyle(
                                color: Color(0xFFD50000),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: total > 0 ? (active / total) : 0.0,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFD50000).withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD50000)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isLoading 
                            ? "Fetching live data telemetry..." 
                            : "System operational capacity is currently at ${health}% overall readiness.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11.5,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),"""

# Modules match
old_module_pattern = """                        const BlinkingActiveBadge(),
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
                        ),"""

# Dashboard.dart match (different colors/const markup)
old_dashboard_pattern = """                                const BlinkingActiveBadge(),
                                const SizedBox(height: 12),
                                const Text(
                                  "Asset Management",
                                  style: TextStyle(
                                    color: Color(0xFF202124),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  "Manage inspections, check real-time status, and ensure regulatory readiness.",
                                  style: TextStyle(
                                    color: Color(0xFF5F6368),
                                    fontSize: 12,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),"""

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    updated = False
    
    # Check which pattern is in file
    if old_module_pattern in content:
        content = content.replace(old_module_pattern, live_gauge_code)
        updated = True
    elif old_dashboard_pattern in content:
        # Adjust indentation slightly for dashboard.dart's context
        indented_gauge = ""
        for line in live_gauge_code.split('\n'):
            indented_gauge += "        " + line + "\n"
        indented_gauge = indented_gauge.rstrip()
        
        content = content.replace(old_dashboard_pattern, indented_gauge)
        updated = True

    if updated:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Successfully injected hyper-premium Live Telemetry Gauge Console into {count} dashboards!")
