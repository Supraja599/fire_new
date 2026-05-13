import os
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'

count = 0
for root, _, files in os.walk(lib_dir):
    if root == lib_dir: continue
    folder = os.path.basename(root)
    if folder in ['icons', 'services', 'widgets']: continue
    
    for f in files:
        if f == 'dashboard.dart' or f == 'sprinkler.dart':
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
                
            original_content = content
            
            # The target block to inject the back button
            target = """              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,"""
                      
            replacement = """              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Navigator.canPop(context))
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,"""
                      
            if target in content:
                content = content.replace(target, replacement)
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(content)
                count += 1
                print(f"Added back button to {folder}/{f}")

print(f"Total dashboards updated with back button: {count}")
