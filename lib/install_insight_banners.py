import os
import re

def add_insight_banner(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Try to find the module name
    title = "Safety Ecosystem"
    
    # Search for Text("Something", style: TextStyle(color: Colors.grey[900], fontSize: 24, fontWeight: FontWeight.bold))
    title_match = re.search(r'Text\(\s*"([^"]+)",\s*style:\s*TextStyle\(\s*color:\s*Colors\.grey\[900\],\s*fontSize:\s*24', content)
    if not title_match:
        title_match = re.search(r'Text\(\s*"([^"]+)",\s*style:\s*TextStyle\(\s*fontSize:\s*24', content)
        
    if title_match:
        title = title_match.group(1).strip()
    
    # Specific fallback for global master dashboard
    if "dashboard.dart" in filepath and os.path.dirname(filepath).endswith("lib"):
        title = "Console"

    # Adjust specific titles for cleanliness
    if title == "Extinguisher": title = "Fire Extinguisher"

    banner_code = f"""
            // New: Gorgeous Executive Insight Banner to fill empty space elegantly!
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD50000).withValues(alpha: 0.05),
                    const Color(0xFFD50000).withValues(alpha: 0.01),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFD50000).withValues(alpha: 0.1),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD50000).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.insights_rounded, color: Color(0xFFD50000), size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "{title} Intelligence Hub",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF202124),
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Active security matrix verified. Environmental sensors and device telemetry synchronized.",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5F6368),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),"""

    # Target const SizedBox(height: 8), immediately followed by // Action Grid
    target = r'const SizedBox\(\s*height:\s*8\s*\)\s*,\s*(?=\s*//\s*Action\s*Grid)'
    
    if "Intelligence Hub" in content:
        return False

    new_content, count = re.subn(target, banner_code, content)
    if count > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Injected Insight Banner into {filepath} (Title: {title})")
        return True
    return False

total_fixed = 0
for root, dirs, files in os.walk('lib'):
    for file in files:
        filename = file.lower()
        if filename.endswith('dashboard.dart') or filename == 'sprinkler.dart':
            path = os.path.join(root, file)
            if add_insight_banner(path):
                total_fixed += 1

print(f"Done! Injected banner into {total_fixed} files.")
