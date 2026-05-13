import os
import re

NEW_CODE_TEMPLATE = """  @override
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
{cards}
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
}"""

STANDARD_ICONS = {
    "Analytics": ("Icons.bar_chart_rounded", "Trends"),
    "Plant Health": ("Icons.monitor_heart_rounded", "Score"),
    "Alerts": ("Icons.emergency_rounded", "Critical"),
    "Maintenance": ("Icons.construction_rounded", "Service"),
    "Reports": ("Icons.history_edu_rounded", "Logs"),
    "Checklist": ("Icons.library_books_rounded", "Forms"),
    "Inspection": ("Icons.fact_check_rounded", "Scan"),
}

def extract_pages(content):
    pages = {}
    page_matches = re.findall(r'([A-Za-z0-9_]+Page)\(\)', content)
    for p in page_matches:
        p_lower = p.lower()
        if 'alert' in p_lower: pages['Alerts'] = p
        elif 'health' in p_lower: pages['Plant Health'] = p
        elif 'main' in p_lower: pages['Maintenance'] = p
        elif 'report' in p_lower: pages['Reports'] = p
        elif 'check' in p_lower: pages['Checklist'] = p
        elif 'scan' in p_lower or 'inspect' in p_lower: pages['Inspection'] = p
        elif 'analytic' in p_lower: pages['Analytics'] = p
    return pages

def get_module_name(folder):
    parts = folder.split('_')
    return ' '.join(p.capitalize() for p in parts)

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
count = 0

for root, _, files in os.walk(lib_dir):
    if root == lib_dir: continue # skip root dashboard
    folder = os.path.basename(root)
    if folder == 'fire_extinguisher': continue # Skip the reference folder
    if folder in ['icons', 'services', 'widgets']: continue
    
    for f in files:
        if f == 'dashboard.dart' or f == 'sprinkler.dart':
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            pages = extract_pages(content)
            module_name = get_module_name(folder)
            
            # Reconstruct cards
            # We want to match the fire_extinguisher order: Analytics(or Plant Health for others), Inspection, Maintenance, Alerts, Plant Health(already there), Reports
            # Actually, standard for other modules is: Plant Health, Alerts, Maintenance, Reports, Checklist, Inspection
            
            cards_dart = []
            
            # The standard set
            order = ["Plant Health", "Alerts", "Maintenance", "Reports", "Checklist", "Inspection"]
            for title in order:
                if title in pages:
                    icon, sub = STANDARD_ICONS[title]
                    page_widget = f"const {pages[title]}()"
                    card_str = f'                      _ActionCard("{title}", {icon}, const Color(0xFFD32F2F), {page_widget}, "{sub}"),'
                    cards_dart.append(card_str)
                else:
                    # If any standard page is missing but we have it in STANDARD_ICONS
                    pass
            
            # Any extra pages?
            for title, page_name in pages.items():
                if title not in order:
                    icon, sub = STANDARD_ICONS.get(title, ("Icons.widgets", "View"))
                    page_widget = f"const {page_name}()"
                    card_str = f'                      _ActionCard("{title}", {icon}, const Color(0xFFD32F2F), {page_widget}, "{sub}"),'
                    cards_dart.append(card_str)
                    
            cards_block = "\n".join(cards_dart)
            
            # Form the new code block
            new_code = NEW_CODE_TEMPLATE.replace("{module_name}", module_name).replace("{cards}", cards_block)
            
            # Replace from build onwards
            match = re.search(r'(@override\s+Widget build\(BuildContext context\) \{)', content)
            if match:
                start_idx = match.start()
                new_content = content[:start_idx] + new_code
                
                # Check for HealthScoreWidget import
                if 'package:fire_new/widgets/health_score_widget.dart' not in new_content:
                    # Inject after the first import
                    import_idx = new_content.find("import ")
                    if import_idx != -1:
                        end_import = new_content.find("\n", import_idx)
                        new_content = new_content[:end_import+1] + "import 'package:fire_new/widgets/health_score_widget.dart';\n" + new_content[end_import+1:]
                
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print(f"Updated {folder}/{f}")
                count += 1
            else:
                print(f"Could not find build method in {folder}/{f}")

print(f"Updated {count} dashboards.")
