const fs = require('fs');
const path = require('path');

// Pattern A: inspection.dart style (compact Row)
const OLD = `                  ...item!.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Expanded(flex: 4, child: Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
                      Expanded(flex: 6, child: Text(e.value?.toString() ?? "-")),
                    ]),
                  )).toList(),`;
const NEW = `                  ...buildDetailRows(item!),`;

// Pattern B: scan.dart style (expanded Row)
const OLD2 = `                    ...item!.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              e.key.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey),
                            ),
                          ),
                          Expanded(flex: 6, child: Text(e.value?.toString() ?? "-")),
                        ],
                      ),
                    )).toList(),`;
const NEW2 = `                    ...buildDetailRows(item!),`;
const IMPORT = `import 'package:fire_new/utils/map_flatten.dart';`;

function walk(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  let results = [];
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) results = results.concat(walk(full));
    else if (e.name === 'inspection.dart' || e.name === 'scan.dart') results.push(full);
  }
  return results;
}

const files = walk('lib');
let changed = 0;
for (const f of files) {
  let raw = fs.readFileSync(f, 'utf8');
  const crlf = raw.includes('\r\n');
  // Normalize to LF for matching, then restore
  let text = raw.replace(/\r\n/g, '\n');
  const hasA = text.includes(OLD);
  const hasB = text.includes(OLD2);
  if (!hasA && !hasB) continue;
  if (hasA) text = text.replaceAll(OLD, NEW);
  if (hasB) text = text.replaceAll(OLD2, NEW2);
  if (!text.includes(IMPORT)) {
    const lines = text.split('\n');
    let last = 0;
    for (let i = 0; i < lines.length; i++) if (lines[i].startsWith('import ')) last = i;
    lines.splice(last + 1, 0, IMPORT);
    text = lines.join('\n');
  }
  if (crlf) text = text.replace(/\n/g, '\r\n');
  fs.writeFileSync(f, text, 'utf8');
  changed++;
  console.log('fixed: ' + f);
}
console.log('\nTotal fixed: ' + changed);
