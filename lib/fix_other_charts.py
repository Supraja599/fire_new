import os

def fix_specific_chart(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    replacements = {
        'getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 10), child: Text(["ACT", "SVC", "INS", "EXP"][v.toInt()], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)))))':
        """getTitlesWidget: (v, _) {
                            int idx = v.toInt();
                            if (idx < 0 || idx > 3) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                ["ACT", "SVC", "INS", "EXP"][idx],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                            );
                          }))""",
        'getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 10), child: Text(["ACT", "FLT", "INS", "EXP"][v.toInt()], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)))))':
        """getTitlesWidget: (v, _) {
                            int idx = v.toInt();
                            if (idx < 0 || idx > 3) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                ["ACT", "FLT", "INS", "EXP"][idx],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                            );
                          }))"""
    }

    modified = False
    for target, replacement in replacements.items():
        if target in content:
            content = content.replace(target, replacement)
            modified = True
        
        target_win = target.replace('\n', '\r\n')
        if target_win in content:
            content = content.replace(target_win, replacement.replace('\n', '\r\n'))
            modified = True

    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Patched specific chart crash in: {filepath}")
        return True

    return False

paths = [
    'lib/smoke_detector/planthealth.dart',
    'lib/fire_trolley/planthealth.dart',
    'lib/alarm_panel/planthealth.dart'
]

total = 0
for path in paths:
    if os.path.exists(path):
        if fix_specific_chart(path):
            total += 1

print(f"Done! Fixed {total} remaining charts.")
