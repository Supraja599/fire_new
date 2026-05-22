import os
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
    # Skip root dashboard since that is our source of truth
    if os.path.abspath(path) == os.path.abspath(os.path.join(lib_dir, 'dashboard.dart')):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    start_marker = "// Action Grid"
    end_marker = "children: ["
    
    if start_marker in content and end_marker in content:
        start_idx = content.find(start_marker)
        end_idx = content.find(end_marker)
        
        # Replace from // Action Grid up to children: [
        new_grid_header = """// Action Grid
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                int crossAxisCount = 2;
                if (screenWidth > 900) {
                  crossAxisCount = 4;
                } else if (screenWidth > 600) {
                  crossAxisCount = 3;
                }
                final double aspectRatio = screenWidth > 600 ? 1.2 : 1.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: aspectRatio,
                    """
                    
        content = content[:start_idx] + new_grid_header + content[end_idx:]
        
        # Also need to ensure we close the Builder properly!
        # The original code ended with:
        #                 );
        #               },
        #             ),
        # Let's see what was replaced. Original code was LayoutBuilder( builder: (context, constraints) { ... return Padding(...); }, )
        # My Builder also has: Builder( builder: (context) { ... return Padding(...); } )
        # Wait, Builder is closed with ); }, ), just like LayoutBuilder!
        # Let's check what is actually at the end of the children array.
        # In original:
        #                     ],
        #                   ),
        #                 );
        #               },
        #             ),
        # Since both Builder and LayoutBuilder use the exact same closing syntax, nothing else needs to change!
        
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Successfully unified grid layout for {count} module dashboards!")
