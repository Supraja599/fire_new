import os

replacements = {
    r'alarm_panel\dashboard.dart': 'alarm_panel.png',
    r'hydrant\dashboard.dart': 'firehydrant.png',
    r'emergency_exits\dashboard.dart': 'emergency_exit.png',
    r'pa_system\dashboard.dart': 'pa_system.png',
}

base_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'

target_string = """                        const SizedBox(height: 5),
                        Text(
                          "Company Eltrive",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  HealthScoreWidget(health: health),"""

for rel_path, img_name in replacements.items():
    full_path = os.path.join(base_dir, rel_path)
    if os.path.exists(full_path):
        with open(full_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        replacement_string = """                        const SizedBox(height: 5),
                        Text(
                          "Company Eltrive",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset('assets/""" + img_name + """', height: 80, fit: BoxFit.contain, errorBuilder: (c, e, s) => const SizedBox()),
                  const SizedBox(width: 15),
                  HealthScoreWidget(health: health),"""
                  
        if target_string in content:
            new_content = content.replace(target_string, replacement_string)
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print('Updated', rel_path)
        else:
            print('Could not find target string in', rel_path)
    else:
        print('File not found', full_path)
