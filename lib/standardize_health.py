import os
import re

def standardize_health_widget(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Identify the hardcoded health indicator pattern
    # It usually starts with a Container and has Icons.favorite
    pattern = r'Container\(\s*padding: const EdgeInsets\.symmetric\(horizontal: 10, vertical: 6\),[\s\S]*?Icons\.favorite[\s\S]*?Text\("\$health%"[\s\S]*?\)\s*,'
    
    if 'Icons.favorite' in content and 'HealthScoreWidget' not in content:
        # Replace the hardcoded block with the widget call
        new_content = re.sub(pattern, 'HealthScoreWidget(health: health),', content)
        
        # Ensure the import for HealthScoreWidget is present
        if 'HealthScoreWidget' in new_content and 'health_score_widget.dart' not in new_content:
            new_content = "import 'package:fire_new/widgets/health_score_widget.dart';\n" + new_content
            
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
    return False

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
fixed = 0
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart') and ('dashboard' in file.lower() or file == 'sprinkler.dart'):
            if standardize_health_widget(os.path.join(root, file)):
                fixed += 1

print(f"Standardized health widget in {fixed} dashboard files.")
