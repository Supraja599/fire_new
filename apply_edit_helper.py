import os
import re

def parse_brace_block(content, start_idx):
    brace_start = content.find('{', start_idx)
    if brace_start == -1:
        return None
    
    count = 1
    i = brace_start + 1
    while i < len(content) and count > 0:
        if content[i] == '{':
            count += 1
        elif content[i] == '}':
            count -= 1
        i += 1
    return brace_start, i

def process_file(filepath):
    print(f"Processing: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Skip files that have already been converted to EditHelper
    if 'EditHelper.editDetails' in content:
        print(" -> Already converted.")
        return

    # Find the API service name dynamically
    # Matches:
    # 1) saveSingleModuleRecord(moduleCode: SpillKitsApiService.moduleCode
    # 2) saveSingleModuleRecord(moduleCode: "smoke_detector"
    api_match = re.search(r'saveSingleModuleRecord\(\s*moduleCode\s*:\s*(?:([\w.]+)\.moduleCode|"(\w+)")', content)
    if not api_match:
        print(" -> Error: Could not locate saveSingleModuleRecord to extract moduleCode.")
        return
    
    if api_match.group(1):
        module_code_expr = f"{api_match.group(1)}.moduleCode"
    else:
        module_code_expr = f'"{api_match.group(2)}"'
        
    print(f" -> Extracted Module Code Expression: {module_code_expr}")

    # Find the edit method definition name (usually _editDetails or editAllFields)
    edit_method_name = None
    if 'void _editDetails()' in content:
        edit_method_name = '_editDetails'
    elif 'void editAllFields()' in content:
        edit_method_name = 'editAllFields'
    
    if edit_method_name:
        # File has edit details method, replace it
        method_def = f"void {edit_method_name}()"
        idx = content.find(method_def)
        if idx == -1:
            print(f" -> Error: Could not locate {method_def} index.")
            return

        block_range = parse_brace_block(content, idx)
        if not block_range:
            print(" -> Error: Could not parse method braces.")
            return
        
        brace_start, brace_end = block_range

        replacement = f"""{{
    if (item == null) return;
    EditHelper.editDetails(
      context: context,
      item: item!,
      moduleCode: {module_code_expr},
      equipmentId: (item!["sos_code"] ?? item!["equipment_id"] ?? item!["id"] ?? "").toString(),
      onSaved: () => setState(() {{}}),
    );
  }}"""

        content = content[:brace_start] + replacement + content[brace_end:]

        # Add Timeline Button in AppBar actions next to Edit details button
        edit_button_pattern = r'IconButton\(\s*icon\s*:\s*const\s*Icon\(Icons\.edit\)\s*,\s*onPressed\s*:\s*(_?editDetails|editAllFields)\s*\)'
        timeline_button = f"""IconButton(icon: const Icon(Icons.edit), onPressed: {edit_method_name}),
              if (item != null)
                IconButton(
                  icon: const Icon(Icons.timeline_rounded, color: Colors.white),
                  onPressed: () {{
                    final id = item!['sos_code'] ?? item!['id'] ?? item!['equipment_id'] ?? '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EquipmentHistoryPage(
                          equipmentId: id.toString(),
                        ),
                      ),
                    );
                  }},
                )"""
        content, count = re.subn(edit_button_pattern, timeline_button, content)
        if count == 0:
            print(" -> Warning: Timeline button could not be auto-injected next to existing edit button.")
    else:
        # File does not have edit details method. Inject it before build()!
        build_idx = content.find("Widget build(")
        if build_idx == -1:
            build_idx = content.find("@override\n  Widget build(")
        
        if build_idx == -1:
            print(" -> Error: Could not locate Widget build( in scan file.")
            return
        
        edit_method_code = f"""  void _editDetails() {{
    if (item == null) return;
    EditHelper.editDetails(
      context: context,
      item: item!,
      moduleCode: {module_code_expr},
      equipmentId: (item!["sos_code"] ?? item!["equipment_id"] ?? item!["id"] ?? "").toString(),
      onSaved: () => setState(() {{}}),
    );
  }}

"""
        content = content[:build_idx] + edit_method_code + content[build_idx:]
        
        # Inject the new buttons in AppBar actions: [
        content = content.replace(
            "actions: [",
            "actions: [\n          if (item != null) IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: _editDetails),\n          if (item != null) IconButton(icon: const Icon(Icons.timeline_rounded, color: Colors.white), onPressed: () { final id = item!['sos_code'] ?? item!['id'] ?? item!['equipment_id'] ?? ''; Navigator.push(context, MaterialPageRoute(builder: (_) => EquipmentHistoryPage(equipmentId: id.toString()))); }),"
        )
        print(" -> Injected new _editDetails method and AppBar buttons.")

    # Add imports
    imports = "\nimport '../utils/edit_helper.dart';\nimport '../screens/equipment_history_page.dart';\n"
    first_import = content.find("import ")
    if first_import != -1:
        content = content[:first_import] + imports + content[first_import:]
    else:
        content = imports + content

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(" -> Success!")

def main():
    lib_dir = r"c:\Users\A\AndroidStudioProjects\Fire_New\lib"
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            # Skip root lib files (like lib/inspection.dart which is already done)
            if root == lib_dir:
                continue
            
            if file in ('scan.dart', 'inspection.dart'):
                filepath = os.path.join(root, file)
                try:
                    process_file(filepath)
                except Exception as e:
                    print(f" -> Failed to process {filepath}: {e}")

if __name__ == '__main__':
    main()
