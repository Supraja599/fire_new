import os

def fix_chart(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Safe exact string match
    target = 'getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(["ACTIVE", "SERVICE", "INSPECT", "EXPIRED"][v.toInt()], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)))))'

    replacement = """getTitlesWidget: (v, _) {
                    int idx = v.toInt();
                    if (idx < 0 || idx > 3) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        ["ACTIVE", "SERVICE", "INSPECT", "EXPIRED"][idx],
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    );
                  }))"""

    if target in content:
        new_content = content.replace(target, replacement)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed chart crash in: {filepath}")
        return True
    
    target_win = target.replace('\n', '\r\n')
    if target_win in content:
        new_content = content.replace(target_win, replacement.replace('\n', '\r\n'))
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed chart crash (CRLF) in: {filepath}")
        return True

    return False

total_fixed = 0
for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('planthealth.dart'):
            path = os.path.join(root, file)
            if fix_chart(path):
                total_fixed += 1

print(f"Done! Patched {total_fixed} plant health charts.")
