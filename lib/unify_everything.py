import os
import re

NEW_BUILD_TEMPLATE = """  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // Red Header Section
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: width * 0.05),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Navigator.canPop(context))
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "{module_name}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.07,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Company Eltrive",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  HealthScoreWidget(health: health),
                ],
              ),
            ),
             const SizedBox(height: 10),

            // Safety Gauge
            SafetyGaugeWidget(
              active: summaryData?["active_units"] ?? summaryData?["active"] ?? 0,
              expired: summaryData?["expired"] ?? 0,
              needsService: summaryData?["needs_service"] ?? summaryData?["needs-service"] ?? 0,
              inspection: summaryData?["needs_inspection"] ?? summaryData?["inspection"] ?? 0,
              health: health,
              moduleName: "{module_name}",
              api: api,
            ),
            
            // Action Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final double textScale = MediaQuery.textScalerOf(context).scale(1);
                int crossAxisCount = 3;
                
                double aspectRatio = (0.85 / textScale).clamp(0.6, 0.9);
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: aspectRatio,
                    children: [
                      _ActionCard("Analytics", Icons.bar_chart_rounded, const Color(0xFFD32F2F), const {p_analytics}(), "Trends"),
                      _ActionCard("Inspection", Icons.fact_check_rounded, const Color(0xFFD32F2F), const {p_inspection}(), "Scan"),
                      _ActionCard("Maintenance", Icons.construction_rounded, const Color(0xFFD32F2F), const {p_maintenance}(), "Service"),
                      _ActionCard("Alerts", Icons.emergency_rounded, const Color(0xFFD32F2F), const {p_alerts}(), "Critical"),
                      _ActionCard("Plant Health", Icons.monitor_heart_rounded, const Color(0xFFD32F2F), const {p_planthealth}(), "Score"),
                      _ActionCard("Reports", Icons.history_edu_rounded, const Color(0xFFD32F2F), const {p_reports}(), "Logs"),
                    ],
                  ),
                );
              },
            ),

            // Inspection Streak
            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
              child: Center(
                child: Text(
                  "Inspection Streak: 0 months",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: width * 0.035,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  final String? subtitle;

  const _ActionCard(this.title, this.icon, this.color, this.page, [this.subtitle]);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: EdgeInsets.all(width * 0.025),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFFD32F2F).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: width * 0.08),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: width * 0.035,
                ),
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: width * 0.025,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
"""

def extract_pages(content):
    pages = {}
    page_matches = re.findall(r'([A-Za-z0-9_]+Page)\(\)', content)
    for p in page_matches:
        p_lower = p.lower()
        if 'alert' in p_lower: pages['Alerts'] = p
        elif 'health' in p_lower: pages['Plant Health'] = p
        elif 'main' in p_lower: pages['Maintenance'] = p
        elif 'report' in p_lower: pages['Reports'] = p
        elif 'check' in p_lower: pages['Analytics'] = p # Map Checklist to Analytics
        elif 'scan' in p_lower or 'inspect' in p_lower: pages['Inspection'] = p
        elif 'analytic' in p_lower: pages['Analytics'] = p
    return pages

def get_module_name(folder):
    parts = folder.split('_')
    return ' '.join(p.capitalize() for p in parts)

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
count = 0

for root, _, files in os.walk(lib_dir):
    if root == lib_dir: continue
    folder = os.path.basename(root)
    if folder in ['icons', 'services', 'widgets']: continue
    
    for f in files:
        if f == 'dashboard.dart' or f == 'sprinkler.dart':
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # Extract the actual page classes for this module
            pages = extract_pages(content)
            module_name = get_module_name(folder)
            
            # Form the new code block
            new_code = NEW_BUILD_TEMPLATE.replace("{module_name}", module_name)
            new_code = new_code.replace("{p_analytics}", pages.get('Analytics', 'SizedBox'))
            new_code = new_code.replace("{p_inspection}", pages.get('Inspection', 'SizedBox'))
            new_code = new_code.replace("{p_maintenance}", pages.get('Maintenance', 'SizedBox'))
            new_code = new_code.replace("{p_alerts}", pages.get('Alerts', 'SizedBox'))
            new_code = new_code.replace("{p_planthealth}", pages.get('Plant Health', 'SizedBox'))
            new_code = new_code.replace("{p_reports}", pages.get('Reports', 'SizedBox'))
            
            # Find the build method
            match = re.search(r'(@override\s+Widget build\(BuildContext context\) \{)', content)
            if not match:
                print(f"Could not find build method in {folder}/{f}")
                continue
                
            start_idx = match.start()
            new_content = content[:start_idx] + new_code
            
            # 1. Inject Map<String, dynamic>? summaryData;
            if 'Map<String, dynamic>? summaryData;' not in new_content:
                new_content = re.sub(r'(bool isLoading = true;)', r'\1\n  Map<String, dynamic>? summaryData;', new_content)
                
            # 2. Inject summaryData = s;
            if 'summaryData = s;' not in new_content:
                new_content = re.sub(r'(health = ApiService\.calculateHealth\(s\);)', r'summaryData = s;\n          \1', new_content)
                
            # Check for HealthScoreWidget import
            if 'package:fire_new/widgets/health_score_widget.dart' not in new_content:
                new_content = "import 'package:fire_new/widgets/health_score_widget.dart';\n" + new_content

            # Check for SafetyGaugeWidget import
            if 'package:fire_new/widgets/safety_gauge_widget.dart' not in new_content:
                new_content = "import 'package:fire_new/widgets/safety_gauge_widget.dart';\n" + new_content

            with open(path, 'w', encoding='utf-8') as file:
                file.write(new_content)
            print(f"Unified {folder}/{f}")
            count += 1

print(f"Unified {count} dashboards.")
