import os
import re

def fix_dashboard(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Convert Column to ListView in SafeArea
    # Target: body: SafeArea( child: Column( children: [ ... ] ) )
    content = re.sub(
        r'body:\s+SafeArea\(\s+child:\s+Column\((\s+children:\s+\[)',
        r'body: SafeArea(\n        child: ListView(\n          physics: const BouncingScrollPhysics(),\n          children: [',
        content
    )

    # 2. Fix GridView: Remove Expanded, Add shrinkWrap, Add physics
    # Target: Expanded( child: GridView.count( ... ) )
    content = re.sub(
        r'Expanded\(\s+child:\s+GridView\.count\(',
        r'GridView.count(\n                shrinkWrap: true,\n                physics: const NeverScrollableScrollPhysics(),',
        content
    )
    
    # 3. Add FittedBox to Action Card Titles
    # Target: Text( title, ... style: ... ) inside _ActionCard Column
    # We find the Column inside _ActionCard and the Text widget
    if '_ActionCard' in content:
        # Replace Text(title, ...) with FittedBox(fit: BoxFit.scaleDown, child: Text(title, ...))
        content = re.sub(
            r'Text\(\s+title,\s+textAlign: TextAlign\.center,\s+style: const TextStyle\((.*?)\)\s+\)',
            r'FittedBox(fit: BoxFit.scaleDown, child: Text(title, textAlign: TextAlign.center, style: const TextStyle(\1)))',
            content
        )
        # Also handle standard Text(title, ...)
        content = re.sub(
            r'Text\(\s+title,\s+style:\s+const\s+TextStyle\((.*?)\)\s+\)',
            r'FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: const TextStyle(\1)))',
            content
        )

    # 4. Wrap Metric Rows in Wrap widget to prevent horizontal overflow
    # Target: Row( children: [ _metricTile(...), ... ] )
    content = re.sub(
        r'Row\(\s+children: \[\s+(_metricTile\(.*?\)),\s+(?:const SizedBox\(width: \d+\),\s+)?(_metricTile\(.*?\))\s+\],?\s+\)',
        r'Wrap(\n                spacing: 15,\n                runSpacing: 15,\n                alignment: WrapAlignment.center,\n                children: [\n                  \1,\n                  \2,\n                ])',
        content
    )

    # 5. Fix closing brackets if we changed Column to ListView
    # Since ListView children list ends with ] ) ), and original Column ended with ] ) ),
    # we just need to ensure we didn't leave an extra Expanded closing brace.
    # Actually, the regex in #2 removed the Expanded( part, so we need to remove one closing )
    # This is tricky, let's just count the parentheses or use a cleaner replacement.
    
    # Simple cleanup for the Expanded closure
    # Find the pattern of GridView closing and remove the extra paren from Expanded
    content = re.sub(r'\s+childAspectRatio:.*?\n\s+children: \[.*?\n\s+\],\n\s+\),\n\s+\),', r'\0', content, flags=re.DOTALL)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Fixed: {file_path}")

# Walk through all directories in lib
lib_path = 'lib'
for root, dirs, files in os.walk(lib_path):
    for file in files:
        if file == 'dashboard.dart':
            full_path = os.path.join(root, file)
            # Skip the main dashboard and generic dashboard if needed, but here we want to fix ALL
            fix_dashboard(full_path)

print("All dashboards processed.")
