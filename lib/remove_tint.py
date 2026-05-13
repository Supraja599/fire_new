import os
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

for path in dashboards:
    if not os.path.exists(path):
        continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove the color tinting so the white-background images show up correctly
    target = "Image.asset(imagePath, width: width * 0.1, height: width * 0.1, color: Colors.white)"
    replace = "ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(imagePath, width: width * 0.12, height: width * 0.12, fit: BoxFit.cover))"
    
    if target in content:
        content = content.replace(target, replace)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

print("Removed color tint from images!")
