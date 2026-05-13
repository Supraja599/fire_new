import os
import re

LAYOUT_BUILDER_TEMPLATE = """            LayoutBuilder(
              builder: (context, constraints) {
                final double textScale = MediaQuery.textScalerOf(context).scale(1);
                int crossAxisCount = 3;
                
                double aspectRatio = (0.85 / textScale).clamp(0.6, 0.9);
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: aspectRatio,
                    children: [
{cards}
                    ],
                  ),
                );
              },
            ),"""

NEW_CARD_CODE = """class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  final String? subtitle;

  const _ActionCard(this.title, this.icon, this.color, this.page, [this.subtitle]);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: EdgeInsets.all(width * 0.025),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFFD32F2F).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: width * 0.08),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: width * 0.035,
                ),
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: width * 0.025,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}"""

STANDARD_ICONS = {
    "Analytics": ("Icons.bar_chart_rounded", "Trends"),
    "Inspection": ("Icons.fact_check_rounded", "Scan"),
    "Scan": ("Icons.fact_check_rounded", "Scan"),
    "Maintenance": ("Icons.construction_rounded", "Service"),
    "Alerts": ("Icons.emergency_rounded", "Critical"),
    "Plant Health": ("Icons.monitor_heart_rounded", "Score"),
    "Reports": ("Icons.history_edu_rounded", "Logs"),
    "Checklist": ("Icons.library_books_rounded", "Forms"),
}

def replace_class(content):
    start_idx = content.find("class _ActionCard extends StatelessWidget")
    if start_idx == -1: return content
    
    brace_count = 0
    in_class = False
    end_idx = -1
    
    for i in range(start_idx, len(content)):
        if content[i] == '{':
            brace_count += 1
            in_class = True
        elif content[i] == '}':
            brace_count -= 1
        
        if in_class and brace_count == 0:
            end_idx = i
            break
            
    if end_idx != -1:
        return content[:start_idx] + NEW_CARD_CODE + content[end_idx+1:]
    return content

lib_dir = r"c:\Users\A\AndroidStudioProjects\Fire_New\lib"
count = 0

for root, _, files in os.walk(lib_dir):
    for f in files:
        if f.endswith(".dart") and ('dashboard' in f.lower() or f == 'sprinkler.dart'):
            file_path = os.path.join(root, f)
            with open(file_path, "r", encoding="utf-8") as file:
                content = file.read()
                
            # 1. Update _ActionCard
            content = replace_class(content)
            
            # 2. Extract pages to rewrite LayoutBuilder
            action_cards = re.findall(r'_ActionCard\(\s*"([^"]+)"\s*,\s*[^,]+\s*,\s*[^,]+\s*,\s*(const\s+[a-zA-Z0-9_]+\(\))\s*(?:,\s*"([^"]+)")?\s*\)', content)
            if not action_cards:
                action_cards = re.findall(r'_ActionCard\(\s*"([^"]+)"\s*,\s*[^,]+\s*,\s*[^,]+\s*,\s*(const\s+[a-zA-Z0-9_]+\(\))\s*\)', content)
                
            if action_cards:
                cards_dart = []
                for match in action_cards:
                    title = match[0]
                    page_widget = match[1]
                    
                    icon = STANDARD_ICONS.get(title, ("Icons.widgets_rounded", "View"))[0]
                    subtitle = STANDARD_ICONS.get(title, ("Icons.widgets_rounded", "View"))[1]
                    
                    card_str = f'                      _ActionCard("{title}", {icon}, const Color(0xFFD32F2F), {page_widget}, "{subtitle}"),'
                    cards_dart.append(card_str)
                    
                cards_block = "\n".join(cards_dart)
                new_layout = LAYOUT_BUILDER_TEMPLATE.replace("{cards}", cards_block)
                
                # Replace LayoutBuilder
                layout_pattern = r'LayoutBuilder\(\s*builder\s*:\s*\(context,\s*constraints\)\s*\{[\s\S]*?GridView\.count\([\s\S]*?\]\s*,\s*\)[\s\S]*?\},?\s*\),?'
                new_content = re.sub(layout_pattern, new_layout, content)
                
                if new_content == content:
                    grid_pattern = r'GridView\.count\([\s\S]*?\]\s*,\s*\)'
                    new_content = re.sub(grid_pattern, new_layout, content)
                    
                if new_content != content:
                    with open(file_path, "w", encoding="utf-8") as file:
                        file.write(new_content)
                    count += 1
            else:
                # If no _ActionCard found, maybe just update class
                with open(file_path, "w", encoding="utf-8") as file:
                    file.write(content)

print(f"Standardized {count} dashboards.")
