import os
import glob
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'sprinklers', 'sprinkler.dart'))

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    updated = False
    
    # 1. Replace text color from red (D50000) to safety green (1E8E3E) in the "Active" counter text widget
    # We can target the specific TextStyle adjacent to the "Active" text.
    # Because they all use this common format:
    # Text(..., style: const TextStyle(color: Color(0xFFD50000), fontSize: 12, fontWeight: FontWeight.w900))
    
    old_text_style = """                              style: const TextStyle(
                                color: Color(0xFFD50000),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),"""
                              
    new_text_style = """                              style: const TextStyle(
                                color: Color(0xFF1E8E3E), // Vibrant Safety Green
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),"""
                              
    if old_text_style in content:
        content = content.replace(old_text_style, new_text_style)
        updated = True
    elif """                                color: Color(0xFFD50000),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,""" in content:
        # Handle potential slight indentation variances
        content = content.replace("Color(0xFFD50000),\n                                fontSize: 12,\n                                fontWeight: FontWeight.w900,", "Color(0xFF1E8E3E),\n                                fontSize: 12,\n                                fontWeight: FontWeight.w900,")
        updated = True

    # 2. Replace the LinearProgressIndicator color properties from red to safety green
    old_indicator_colors = """                            backgroundColor: const Color(0xFFD50000).withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD50000)),"""
                            
    new_indicator_colors = """                            backgroundColor: const Color(0xFF1E8E3E).withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E8E3E)),"""
                            
    if old_indicator_colors in content:
        content = content.replace(old_indicator_colors, new_indicator_colors)
        updated = True
    else:
        # Handle alternative indentations
        pattern_bg = r'backgroundColor: const Color\(0xFFD50000\)\.withValues\(alpha: 0\.08\),'
        pattern_fg = r'valueColor: const AlwaysStoppedAnimation<Color>\(Color\(0xFFD50000\)\),'
        if re.search(pattern_bg, content):
            content = re.sub(pattern_bg, 'backgroundColor: const Color(0xFF1E8E3E).withValues(alpha: 0.08),', content)
            content = re.sub(pattern_fg, 'valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E8E3E)),', content)
            updated = True

    if updated:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Successfully shifted telemetry consoles to Safety Green across {count} module dashboards!")
