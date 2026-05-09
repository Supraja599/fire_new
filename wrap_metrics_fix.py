import os
import re

def fix_metrics(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the Row that contains metric tiles and replace it with Wrap
    # We target: Row( children: [ _metricTile(...), ... ] )
    new_content = re.sub(
        r'Row\(\s+(?:mainAxisAlignment:.*?,?\s+)?children: \[\s+(.*?_metricTile.*?|.*?_tag.*?|.*?_statusTag.*?)\s+\],?\s+\)',
        r'Wrap(\n                  spacing: 12,\n                  runSpacing: 12,\n                  alignment: WrapAlignment.center,\n                  children: [\1\n                  ])',
        content, flags=re.DOTALL
    )
    
    # Also handle the Row( children: [ Expanded(child: _metricTile), ... ] ) case
    # If it's a Wrap, we should remove the Expanded inside it as Wrap children shouldn't be Expanded
    if 'Wrap(' in new_content:
        new_content = re.sub(r'Expanded\(\s+child: (.*?_metricTile.*?|.*?_tag.*?|.*?_statusTag.*?)\s+\)', r'\1', new_content, flags=re.DOTALL)

    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Metrics Wrapped: {file_path}")

# Walk through all directories in lib
lib_path = 'lib'
for root, dirs, files in os.walk(lib_path):
    for file in files:
        if file == 'dashboard.dart':
            full_path = os.path.join(root, file)
            fix_metrics(full_path)
