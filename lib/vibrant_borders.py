import os
import re
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

vibrant_action_card = """class _ActionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final Color color;
  final Widget page;
  final String? subtitle;

  const _ActionCard(this.title, this.imagePath, this.color, this.page, [this.subtitle]);

  @override
  Widget build(BuildContext context) {
    final String t = title.toLowerCase();
    List<Color> bgGradient = [Colors.white, Colors.white];
    Color shadowColor = Colors.grey.withValues(alpha: 0.1);
    Color borderColor = Colors.grey.withValues(alpha: 0.3);
    
    // Boost opacity levels to make the colored borders bold, highly visible, and striking!
    if (t.contains("analytics")) {
      shadowColor = const Color(0xFF1A73E8).withValues(alpha: 0.18);
      borderColor = const Color(0xFF1A73E8).withValues(alpha: 0.65);
    } else if (t.contains("inspection")) {
      shadowColor = const Color(0xFF1E8E3E).withValues(alpha: 0.18);
      borderColor = const Color(0xFF1E8E3E).withValues(alpha: 0.65);
    } else if (t.contains("maintenance")) {
      shadowColor = const Color(0xFFF9AB00).withValues(alpha: 0.18);
      borderColor = const Color(0xFFF9AB00).withValues(alpha: 0.65);
    } else if (t.contains("alerts")) {
      shadowColor = const Color(0xFFD93025).withValues(alpha: 0.18);
      borderColor = const Color(0xFFD93025).withValues(alpha: 0.65);
    } else if (t.contains("plant health")) {
      shadowColor = const Color(0xFF0097A7).withValues(alpha: 0.18);
      borderColor = const Color(0xFF0097A7).withValues(alpha: 0.65);
    } else if (t.contains("reports")) {
      shadowColor = const Color(0xFF9334E6).withValues(alpha: 0.18);
      borderColor = const Color(0xFF9334E6).withValues(alpha: 0.65);
    }
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: borderColor,
            width: 2.2, // Bold 2.2px width for ultimate visual definition
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 6,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, left: 12.0, right: 12.0, bottom: 4.0),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF202124),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}"""

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
    if os.path.abspath(path) == os.path.abspath(os.path.join(lib_dir, 'dashboard.dart')):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    pattern = r'class _ActionCard[\s\S]*?\}\s*\}\s*$'
    if 'class _ActionCard' in content:
        content = re.sub(pattern, vibrant_action_card, content)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Successfully boosted visual border vibrancy in {count} module dashboards!")
