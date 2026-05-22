import os
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'sprinklers', 'sprinkler.dart'))

old_static_badge = """                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD50000).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "SYSTEM ACTIVE",
                            style: TextStyle(
                              color: Color(0xFFD50000),
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),"""

new_pulsing_badge = "                        const BlinkingActiveBadge(),"

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    updated = False
    
    # 1. Inject the Blinking Badge Import if not already present
    import_statement = "import 'package:fire_new/widgets/blinking_badge.dart';"
    if import_statement not in content:
        content = "import 'package:fire_new/widgets/blinking_badge.dart';\n" + content
        updated = True
        
    # 2. Replace Static Container badge with dynamic Pulsing badge
    if old_static_badge in content:
        content = content.replace(old_static_badge, new_pulsing_badge)
        updated = True
        
    # 3. Super-size the Hero banner image dimensions in this file
    # Search for the Hero block in the banner
    if 'tag: "hero_image_' in content:
        old_dims = """                      width: 75,
                      height: 75,"""
        new_dims = """                      width: 95,
                      height: 95,"""
        if old_dims in content:
            content = content.replace(old_dims, new_dims)
            updated = True

    if updated:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Successfully deployed Blinking Heartbeat Badges and Super-sized banner images to 95px in {count} dashboards!")
