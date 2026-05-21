import os
import re

def modify_inspection_files():
    lib_dir = "."
    modified_count = 0
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file == "inspection.dart":
                filepath = os.path.join(root, file)
                print(f"Checking: {filepath}")
                
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                
                # Check if class matches pattern
                class_pattern = r"class\s+(\w*(?:InspectionPage|InspectionPage))\s+extends\s+StatefulWidget\s*\{"
                match = re.search(class_pattern, content)
                if not match:
                    print(f"  No matching class found in {filepath}")
                    continue
                    
                classname = match.group(1)
                
                # Check if already modified
                if "final String? preScannedId;" in content:
                    print(f"  Already modified: {filepath}")
                    continue
                
                # 1. Modify the constructor to add preScannedId
                # Look for the const ClassName({super.key});
                constructor_pattern = rf"const\s+{classname}\s*\(\{{\s*super\.key\s*\}}\)\s*;"
                if re.search(constructor_pattern, content):
                    replacement = f"final String? preScannedId;\n  const {classname}({{super.key, this.preScannedId}});"
                    new_content = re.sub(constructor_pattern, replacement, content)
                else:
                    # Try const ClassName({super.key}) : super(key: key); or similar
                    print(f"  Warning: Constructor pattern not matched exactly in {filepath}")
                    continue
                
                # 2. Modify initState to check and call fetchDetails
                # Look for _loadAllEquipment();
                init_pattern = r"_loadAllEquipment\(\)\s*;"
                init_replacement = (
                    "_loadAllEquipment().then((_) {\n"
                    "      if (widget.preScannedId != null && widget.preScannedId!.isNotEmpty) {\n"
                    "        idController.text = widget.preScannedId!;\n"
                    "        fetchDetails(widget.preScannedId!);\n"
                    "      }\n"
                    "    });"
                )
                
                if re.search(init_pattern, new_content):
                    new_content = re.sub(init_pattern, init_replacement, new_content)
                else:
                    print(f"  Warning: _loadAllEquipment() not found in {filepath}")
                    continue
                
                # Save modified content
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(new_content)
                
                print(f"  Successfully modified: {filepath}")
                modified_count += 1
                
    print(f"\nDone! Modified {modified_count} files.")

if __name__ == "__main__":
    modify_inspection_files()
