import os
import glob
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
reports = glob.glob(os.path.join(lib_dir, '**', '*reports*.dart'), recursive=True)

modified_count = 0

for path in reports:
    # Skip the utility file itself
    if os.path.basename(path) == 'report_utils.dart':
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    if 'buildSingleInspectionReportPDF' in content:
        # Match buildSingleInspectionReportPDF( only if not preceded by await
        updated, count = re.subn(r'(?<!await\s)buildSingleInspectionReportPDF\(', 'await buildSingleInspectionReportPDF(', content)
        if count > 0:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(updated)
            print(f"Updated: {os.path.relpath(path, lib_dir)}")
            modified_count += 1

print(f"Completed! Modified {modified_count} reports files.")
