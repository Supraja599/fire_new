import os
import re
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'sprinklers', 'sprinkler.dart'))

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    start_marker = "// Red Header Section"
    end_marker = "// Action Grid"
    
    if start_marker in content and end_marker in content:
        start_idx = content.find(start_marker)
        end_idx = content.find(end_marker)
        
        header_block = content[start_idx:end_idx]
        
        # Extract Title (dynamic name)
        # The title widget looks like Text("Ppe Cabinets", style: ...
        title = ""
        title_match = re.search(r'Text\(\s*"([^"]+)"', header_block)
        if title_match:
            title = title_match.group(1)
            # Make sure we didn't accidentally grab "Company Eltrive" or something else.
            if title == "Company Eltrive" or title == "Inspection Streak: 0 months":
                # Try to find another one
                matches = re.findall(r'Text\(\s*"([^"]+)"', header_block)
                for m in matches:
                    if m != "Company Eltrive":
                        title = m
                        break
                        
        if title:
            minimal_header = f"""// Minimal Header Section
            Container(
              padding: EdgeInsets.only(top: 25, bottom: 20, left: width * 0.05, right: width * 0.05),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (Navigator.canPop(context))
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "{title}",
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Company Eltrive",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  HealthScoreWidget(health: health),
                ],
              ),
            ),
            const SizedBox(height: 5),
            
            """
            
            new_content = content[:start_idx] + minimal_header + content[end_idx:]
            
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            count += 1

print(f"Successfully converted {count} headers to Minimalist White design!")
