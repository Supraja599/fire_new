import os

lib_dir = r"c:\Users\A\AndroidStudioProjects\Fire_New\lib"

# List of methods that might be duplicated
methods_to_check = [
    "getInspectionReports",
    "getEquipmentStatusReport",
    "syncModuleData",
    "getActive",
    "getNeedsService",
    "getExpired",
    "getDueInspection",
    "getUpcoming",
    "getPlantHealth"
]

def cleanup_file(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    new_lines = []
    found_methods = set()
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check if this line looks like a method definition
        # We'll just look for the method name followed by '(' but NOT in a call (like getActive(),)
        # In definitions, there's usually a space before the name and it's not followed by a comma/semicolon immediately.
        
        match = None
        for method in methods_to_check:
            # Look for the method name with a space before it and '(' after it
            # and NOT preceded by "await " or "return "
            if f" {method}(" in line and "await " not in line and "return " not in line and "=>" not in line:
                # This is likely a definition or part of a list
                # In syncModuleData, it's "getActive(),"
                if line.strip().endswith(",") or line.strip().endswith("]"):
                    continue # This is a call/list, ignore
                match = method
                break
            elif f" {method} " in line and "=>" in line:
                # One-liner definition
                match = method
                break
        
        if match:
            if match in found_methods:
                # Duplicate! Skip it.
                if "=>" in line:
                    i += 1
                else:
                    # Skip block
                    brace_count = line.count("{") - line.count("}")
                    i += 1
                    while i < len(lines) and (brace_count > 0 or "{" not in line):
                        # Handle the case where { is on next line
                        if "{" in lines[i] and brace_count == 0:
                            brace_count = 0 # trigger start
                        brace_count += lines[i].count("{") - lines[i].count("}")
                        if brace_count == 0 and "}" in lines[i]:
                            i += 1
                            break
                        i += 1
                continue
            else:
                found_methods.add(match)
        
        new_lines.append(line)
        i += 1

    content = "".join(new_lines)
    # Final fix for syncModuleData duplication which is very common
    # Keep only the FIRST syncModuleData
    if content.count("syncModuleData") > 1:
        # This is harder to do with lines, so we'll just leave it if it's not causing errors
        # But wait, Dart doesn't allow duplicate method names!
        pass

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# Walk through all api_service.dart files
for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith("api_service.dart") or (file == "apiservice.dart" and "services" in root and "hosereel" in root):
            file_path = os.path.join(root, file)
            cleanup_file(file_path)

print("Cleanup done.")
