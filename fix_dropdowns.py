import os
lib_dir = r'C:\Users\A\AndroidStudioProjects\Fire_New\lib'
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file == 'reports.dart':
            fp = os.path.join(root, file)
            with open(fp, 'r', encoding='utf-8') as f: c = f.read()
            old_str = 'items: ["Fire Extinguishers", "Hose Reel", "Drum Hose Reel"].map'
            new_str = 'items: [selectedPlant, "Fire Extinguishers", "Hose Reel", "Drum Hose Reel"].toSet().toList().map'
            if old_str in c:
                c = c.replace(old_str, new_str)
                with open(fp, 'w', encoding='utf-8') as f: f.write(c)
                print('Fixed ' + fp)
