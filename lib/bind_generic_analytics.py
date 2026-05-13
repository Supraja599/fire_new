import os
import glob
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

# Standard title mappings derived from existing assets/folders to ensure semantic beauty
def get_friendly_names(path, content):
    norm_path = os.path.normpath(path).lower()
    
    # 1. Find the asset image from the banner to ensure consistency!
    img_match = re.search(r'tag:\s*"hero_image_(.*?)"', content)
    if not img_match:
        img_match = re.search(r'Image\.asset\(\s*"(assets/.*?\.png)"', content)
    
    img_path = img_match.group(1) if img_match else "assets/extinguisher.png"
    
    # 2. Find the display title from the minimalist header
    title_match = re.search(r'Text\(\s*"(.*?)",\s*style:\s*TextStyle\([\s\S]*?fontSize:\s*24,', content)
    title = title_match.group(1) if title_match else "Safety Device"
    
    # Clean title from linebreaks if any
    title = title.strip().replace('\n', ' ')
    
    # Create short name
    short_name = title.replace("Analytics", "").replace("Dashboard", "").strip()
    if not short_name:
        short_name = "Units"
        
    return title, short_name, img_path

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
    if os.path.abspath(path) == os.path.abspath(os.path.join(lib_dir, 'dashboard.dart')):
        continue # Skip root extinguisher dashboard since its analytics are handled separately
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    title, short_name, img_path = get_friendly_names(path, content)
    print(f"Inspecting: {os.path.relpath(path, lib_dir)} -> Title: {title}, Img: {img_path}")
    
    updated = False
    
    # 1. Inject the Generic Analytics Import
    import_stmt = "import 'package:fire_new/widgets/generic_analytics_page.dart';"
    if import_stmt not in content:
        content = import_stmt + "\n" + content
        updated = True

    # 2. Replace the ActionCard targeted at "Analytics"
    # It looks like: _ActionCard("Analytics", "...", ..., TARGET_PAGE, "...")
    # We want to capture the group that is the page instantiation and replace it.
    
    pattern = r'(_ActionCard\(\s*"Analytics"\s*,\s*".*?"\s*,\s*[^,]+,\s*)(const\s+)?([A-Za-z0-9_]+\([^)]*\))(\s*,\s*".*?"\s*\))'
    
    new_page_code = f"""GenericAnalyticsPage(
                        title: "{title} Analytics",
                        shortName: "{short_name}",
                        assetLabel: "TOTAL {title.upper()}",
                        apiService: api,
                        imagePath: "{img_path}",
                        fallbackIcon: Icons.analytics_rounded,
                      )"""
                      
    def replace_card(m):
        return m.group(1) + new_page_code + m.group(4)
        
    if re.search(r'_ActionCard\(\s*"Analytics"', content):
        # Test regex replacement
        new_content, num_subs = re.subn(pattern, replace_card, content)
        if num_subs > 0:
            content = new_content
            updated = True
        else:
            # Fallback if standard regex didn't match due to multiline/whitespace variances
            pattern_relaxed = r'(_ActionCard\(\s*"Analytics"[\s\S]*?,\s*)(const\s+)?[A-Za-z0-9_]+\(\)([\s\S]*?\))'
            new_content, num_subs = re.subn(pattern_relaxed, r'\1' + new_page_code + r'\3', content)
            if num_subs > 0:
                content = new_content
                updated = True
            else:
                print(f"CRITICAL WARNING: Failed to replace Analytics ActionCard in {os.path.relpath(path, lib_dir)}")

    if updated:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"\nSuccessfully updated {count} module dashboards to point to the hyper-premium Generic Analytics system!")
