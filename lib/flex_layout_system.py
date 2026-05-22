import os
import re
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

flex_action_card = """class _ActionCard extends StatelessWidget {
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
    Color shadowColor = Colors.grey.withValues(alpha: 0.08);
    Color borderColor = Colors.grey.withValues(alpha: 0.1);
    
    if (t.contains("analytics")) {
      bgGradient = [const Color(0xFFE8F0FE), const Color(0xFFD2E3FC)];
      shadowColor = const Color(0xFF1A73E8).withValues(alpha: 0.1);
      borderColor = const Color(0xFF1A73E8).withValues(alpha: 0.15);
    } else if (t.contains("inspection")) {
      bgGradient = [const Color(0xFFE6F4EA), const Color(0xFFCEEAD6)];
      shadowColor = const Color(0xFF1E8E3E).withValues(alpha: 0.1);
      borderColor = const Color(0xFF1E8E3E).withValues(alpha: 0.15);
    } else if (t.contains("maintenance")) {
      bgGradient = [const Color(0xFFFEF7E0), const Color(0xFFFEEFC3)];
      shadowColor = const Color(0xFFF9AB00).withValues(alpha: 0.1);
      borderColor = const Color(0xFFF9AB00).withValues(alpha: 0.15);
    } else if (t.contains("alerts")) {
      bgGradient = [const Color(0xFFFCE8E6), const Color(0xFFFAD2CF)];
      shadowColor = const Color(0xFFD93025).withValues(alpha: 0.1);
      borderColor = const Color(0xFFD93025).withValues(alpha: 0.15);
    } else if (t.contains("plant health")) {
      bgGradient = [const Color(0xFFE4F7FB), const Color(0xFFC2EFF5)];
      shadowColor = const Color(0xFF0097A7).withValues(alpha: 0.1);
      borderColor = const Color(0xFF0097A7).withValues(alpha: 0.15);
    } else if (t.contains("reports")) {
      bgGradient = [const Color(0xFFF3E8FD), const Color(0xFFE9D2FD)];
      shadowColor = const Color(0xFF9334E6).withValues(alpha: 0.1);
      borderColor = const Color(0xFF9334E6).withValues(alpha: 0.15);
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
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 6, // Allots 66% of the card's vertical height safely to the 3D icon
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, left: 12.0, right: 12.0, bottom: 4.0),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain, // Guarantees it fits fully inside space without overflow
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3, // Allots 33% of card's height safely to text
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
        content = re.sub(pattern, flex_action_card, content)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Perfectly distributed Flex layout injected into {count} module dashboards!")
