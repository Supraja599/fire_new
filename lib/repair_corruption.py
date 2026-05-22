import os
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
    # Skip root dashboard
    if os.path.abspath(path) == os.path.abspath(os.path.join(lib_dir, 'dashboard.dart')):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Perform targeted repair
    # 1. Find the start of the new grid header
    grid_marker = "// Action Grid\n            Builder("
    # Wait, let's be flexible with spaces
    grid_idx = content.find("// Action Grid")
    
    if grid_idx != -1:
        # Find the first "children: [" AFTER the // Action Grid marker
        first_children_idx = content.find("children: [", grid_idx)
        
        if first_children_idx != -1:
            # End index of that marker
            delete_start = first_children_idx + len("children: [")
            
            # Find the first "_ActionCard" AFTER delete_start
            action_card_idx = content.find("_ActionCard", delete_start)
            
            if action_card_idx != -1:
                # We want to delete from delete_start to just before _ActionCard (preserving indentation of _ActionCard if possible)
                # Let's find the last newline before _ActionCard to keep the formatting clean
                last_newline = content.rfind("\n", delete_start, action_card_idx)
                if last_newline != -1:
                    delete_end = last_newline
                else:
                    delete_end = action_card_idx
                    
                # Verify we are actually deleting a corrupted block by checking if "Minimal Header" is in the deleted part!
                deleted_block = content[delete_start:delete_end]
                if "// Minimal Header Section" in deleted_block:
                    # REPAIR!
                    repaired_content = content[:delete_start] + content[delete_end:]
                    
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(repaired_content)
                    count += 1

print(f"Successfully repaired {count} corrupted dashboards!")
