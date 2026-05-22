import os
import re
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'sprinklers', 'sprinkler.dart'))

for path in dashboards:
    if not os.path.exists(path):
        continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to remove Safety Gauge
    # Matches from "// Safety Gauge" to the end of the SafetyGaugeWidget(...)
    gauge_pattern = r'\s*// Safety Gauge\s*SafetyGaugeWidget\([\s\S]*?api:\s*api,\s*\),'
    content = re.sub(gauge_pattern, '', content)

    # Regex to remove Inspection Streak
    # Matches from "// Inspection Streak" to the end of its Padding(...) block
    streak_pattern = r'\s*// Inspection Streak\s*Padding\([\s\S]*?child:\s*Text\([\s\S]*?"Inspection Streak[^"]*"[\s\S]*?\)[\s\S]*?\)[\s\S]*?\),'
    content = re.sub(streak_pattern, '', content)

    # Since SafetyGaugeWidget is no longer used, remove the import to avoid warnings
    import_pattern = r"import 'package:fire_new/widgets/safety_gauge_widget\.dart';\n?"
    content = re.sub(import_pattern, '', content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Removed pie charts and streak from all dashboards!")
