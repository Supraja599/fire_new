import os
import re

def fix_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Convert Column to ListView safely
    if 'body: SafeArea(' in content and 'child: Column(' in content:
        # Only replace the first Column after SafeArea
        content = re.sub(
            r'(body:\s+SafeArea\(\s+child:\s+)Column\(',
            r'\1ListView(\n          physics: const BouncingScrollPhysics(),',
            content, count=1
        )

    # 2. Fix GridView: Remove Expanded wrapper and add shrinkWrap/physics
    # This pattern matches Expanded( child: GridView.count(...) )
    # We remove the Expanded and the trailing ),
    grid_pattern = r'Expanded\(\s+child:(\s+Padding\(\s+padding:.*?\s+child:)?\s+GridView\.count\('
    if re.search(grid_pattern, content, re.DOTALL):
        content = re.sub(
            grid_pattern,
            r'\1 GridView.count(\n                shrinkWrap: true,\n                physics: const NeverScrollableScrollPhysics(),',
            content, flags=re.DOTALL
        )
        # Clean up the extra closing ), left by Expanded
        content = re.sub(r'\),\s+\),\s+\],', r'),\n          ],', content, flags=re.DOTALL)

    # 3. Add FittedBox to any Card title
    # Target: Text( title, ... ) or Text( title: title, ... )
    text_patterns = [
        r'Text\(\s+title,\s+textAlign: TextAlign\.center,\s+style: const TextStyle\((.*?)\)\s+\)',
        r'Text\(\s+title,\s+style:\s+const\s+TextStyle\((.*?)\)\s+\)'
    ]
    for p in text_patterns:
        content = re.sub(p, r'FittedBox(fit: BoxFit.scaleDown, child: Text(title, textAlign: TextAlign.center, style: const TextStyle(\1)))', content)

    # 4. Wrap metric Rows in Wrap widget
    content = re.sub(
        r'Row\(\s+children: \[\s+(_metricTile\(.*?\)),\s+(?:const SizedBox\(width: \d+\),\s+)?(_metricTile\(.*?\))\s+\],?\s+\)',
        r'Wrap(spacing: 15, runSpacing: 15, alignment: WrapAlignment.center, children: [\1, \2])',
        content
    )
    content = re.sub(
        r'Row\(\s+children: \[\s+(_miniMetric\(.*?\)),\s+(?:const SizedBox\(width: \d+\),\s+)?(_miniMetric\(.*?\))\s+\],?\s+\)',
        r'Wrap(spacing: 15, runSpacing: 15, alignment: WrapAlignment.center, children: [\1, \2])',
        content
    )

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

lib_path = 'lib'
for root, dirs, files in os.walk(lib_path):
    for file in files:
        if file == 'dashboard.dart':
            fix_file(os.path.join(root, file))

print("Bulk repair complete.")
