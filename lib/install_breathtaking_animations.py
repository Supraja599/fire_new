import glob
import os
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

new_action_card_body = """class _ActionCard extends StatefulWidget {
  final String title;
  final dynamic imagePath; // dynamic to support both String assets and IconData safely!
  final Color color;
  final Widget page;
  final String? subtitle;

  const _ActionCard(this.title, this.imagePath, this.color, this.page, [this.subtitle]);

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final String t = widget.title.toLowerCase();
    List<Color> bgGradient = [Colors.white, Colors.white];
    Color shadowColor = Colors.grey.withValues(alpha: 0.1);
    Color borderColor = Colors.grey.withValues(alpha: 0.3);
    
    // Tailored accent borders and shadows for each card identity!
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
    } else if (t.contains("checklist") || t.contains("forms")) {
      shadowColor = const Color(0xFF3F51B5).withValues(alpha: 0.18);
      borderColor = const Color(0xFF3F51B5).withValues(alpha: 0.65);
    }
    
    // Calculate staggered delay to create dynamic entrance pop!
    int delayMs = 0;
    if (t.contains("inspection")) delayMs = 80;
    elif (t.contains("maintenance")) delayMs = 160;
    elif (t.contains("alerts")) delayMs = 240;
    elif (t.contains("plant health")) delayMs = 320;
    elif (t.contains("reports")) delayMs = 400;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Interval(
        (delayMs / 1000.0).clamp(0.0, 0.6), 
        1.0, 
        curve: Curves.easeOutBack
      ),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.85 + (value * 0.15),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.94),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => widget.page)),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
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
                width: 2.2, 
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 7,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0, left: 8.0, right: 8.0, bottom: 2.0),
                      child: widget.imagePath is IconData
                          ? FittedBox(
                              fit: BoxFit.contain,
                              child: Icon(
                                widget.imagePath as IconData,
                                color: borderColor.withValues(alpha: 1.0),
                              ),
                            )
                          : Image.asset(
                              widget.imagePath as String,
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
                          widget.title,
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
        ),
      ),
    );
  }
}
"""

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    
    # 1. Replace Stateless _ActionCard with Stateful animated _ActionCard
    if "class _ActionCard extends StatelessWidget" in content:
        parts = content.split("class _ActionCard extends StatelessWidget")
        new_content = parts[0] + new_action_card_body
        
    # 2. Upgrade CircularProgressIndicator to a sweeping TweenAnimationBuilder
    # Find the block cleanly using regex:
    progress_regex = re.compile(
        r'(\s*)child:\s*CircularProgressIndicator\(\s*\n'
        r'\s*value:\s*isLoading\s*\?\s*0\.0\s*:\s*\(health\s*/\s*100\.0\),\s*\n'
        r'\s*strokeWidth:\s*9\.5,\s*\n'
        r'\s*backgroundColor:\s*Colors\.grey\.withValues\(alpha:\s*0\.08\),\s*\n'
        r'\s*valueColor:\s*AlwaysStoppedAnimation<Color>\(\s*\n'
        r'\s*isLoading\s*\n'
        r'\s*\?\s*Colors\.grey\s*\n'
        r'\s*:\s*\(health\s*>=\s*85\s*\n'
        r'\s*\?\s*const\s*Color\(0xFF1E8E3E\)\s*\n'
        r'\s*:\s*\(health\s*>=\s*60\s*\?\s*const\s*Color\(0xFFFF8F00\)\s*:\s*const\s*Color\(0xFFD50000\)\)\),\s*\n'
        r'\s*\),\s*\n'
        r'\s*\),'
    )
    
    # Let's write an even more robust regex that handles various spaces:
    robust_regex = r'child:\s*CircularProgressIndicator\(\s*\n\s*value:\s*isLoading[\s\S]*?Color\(0xFFD50000\)\)\),\s*\n\s*\),\s*\n\s*\),'
    
    # Let's match the outer container to get the exact indentation
    match = re.search(r'(\s*)child:\s*CircularProgressIndicator\(\s*\n', new_content)
    if match:
        indent = match.group(1)
        
        replacement = f"""child: TweenAnimationBuilder<double>(
{indent}  tween: Tween<double>(begin: 0.0, end: isLoading ? 0.0 : (health / 100.0)),
{indent}  duration: const Duration(milliseconds: 1400),
{indent}  curve: Curves.fastOutSlowIn,
{indent}  builder: (context, sweepVal, _) {{
{indent}    return CircularProgressIndicator(
{indent}      value: sweepVal,
{indent}      strokeWidth: 9.5,
{indent}      backgroundColor: Colors.grey.withValues(alpha: 0.08),
{indent}      valueColor: AlwaysStoppedAnimation<Color>(
{indent}        isLoading 
{indent}          ? Colors.grey 
{indent}          : (health >= 85 
{indent}              ? const Color(0xFF1E8E3E) 
{indent}              : (health >= 60 ? const Color(0xFFFF8F00) : const Color(0xFFD50000))),
{indent}      ),
{indent}    );
{indent}  }}
{indent}),"""
        
        new_content = re.sub(robust_regex, replacement, new_content, count=1)

    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Injected breathtaking animations into {os.path.relpath(path, lib_dir)}")
        count += 1

print(f"\nCOMPLETE: Installed ultimate animations across {count} dashboards!")
