import os
import re

def update_scan_page(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern to match:
    # onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuidedCaptureWizardPage(selectedEquipment: item,
    #           equipmentImage: 'assets/co_detector.png', nextScreen: CODetectorChecklistPage(selectedEquipment: item)))),
    
    pattern = r"onPressed: \(\) => Navigator\.push\(context, MaterialPageRoute\(builder: \(_\) => GuidedCaptureWizardPage\(selectedEquipment: item,\s+equipmentImage: '(assets/.*?)', nextScreen: (.*?)\(selectedEquipment: item\)\)\)\)"
    
    replacement = r"""onPressed: () {
            if (item != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => \2(selectedEquipment: item)));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => GuidedCaptureWizardPage(
                selectedEquipment: item,
                equipmentImage: '\1',
                nextScreen: \2(selectedEquipment: item),
              )));
            }
          }"""
    
    new_content = re.sub(pattern, replacement, content)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

root_dir = 'c:/Users/A/AndroidStudioProjects/Fire_New/lib'
updated_count = 0
for root, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith('.dart'):
            if update_scan_page(os.path.join(root, file)):
                updated_count += 1
                print(f"Updated: {os.path.join(root, file)}")

print(f"Total updated: {updated_count}")
