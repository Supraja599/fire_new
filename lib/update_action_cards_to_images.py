import os
import re
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

for path in dashboards:
    if not os.path.exists(path):
        continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update _ActionCard instantiations
    content = content.replace('Icons.bar_chart_rounded', '"assets/dashboard_icons/analytics.png"')
    content = content.replace('Icons.fact_check_rounded', '"assets/dashboard_icons/inspection.png"')
    content = content.replace('Icons.construction_rounded', '"assets/dashboard_icons/maintenance.png"')
    content = content.replace('Icons.emergency_rounded', '"assets/dashboard_icons/alerts.png"')
    content = content.replace('Icons.monitor_heart_rounded', '"assets/dashboard_icons/plant_health.png"')
    content = content.replace('Icons.history_edu_rounded', '"assets/dashboard_icons/reports.png"')

    # 2. Update _ActionCard class definition
    if 'final IconData icon;' in content:
        content = content.replace('final IconData icon;', 'final String imagePath;')
        
    if 'Icon(icon, color: Colors.white, size: width * 0.08),' in content:
        content = content.replace(
            'Icon(icon, color: Colors.white, size: width * 0.08),',
            'Image.asset(imagePath, width: width * 0.1, height: width * 0.1, color: Colors.white),'
        )
        
    if 'const _ActionCard(this.title, this.icon, this.color, this.page, [this.subtitle]);' in content:
        content = content.replace(
            'const _ActionCard(this.title, this.icon, this.color, this.page, [this.subtitle]);',
            'const _ActionCard(this.title, this.imagePath, this.color, this.page, [this.subtitle]);'
        )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
        
print("Action Cards updated to use images!")
