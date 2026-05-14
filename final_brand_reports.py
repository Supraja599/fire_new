import os
import glob
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
reports = glob.glob(os.path.join(lib_dir, '**', '*reports*.dart'), recursive=True)

def brand_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Skip main lib/reports.dart as we did that already
    rel = os.path.relpath(path, lib_dir)
    if rel == 'reports.dart':
        return None

    modified = False

    # 1. Inject import
    if "import 'package:flutter/services.dart'" not in content:
        import_to_inject = "import 'package:flutter/services.dart' show rootBundle;\n"
        if "import 'package:flutter/material.dart';" in content:
            content = content.replace(
                "import 'package:flutter/material.dart';",
                "import 'package:flutter/material.dart';\n" + import_to_inject
            )
            modified = True
        else:
            content = import_to_inject + content
            modified = True

    # 2. Inject Logo Loader
    old_pdf_init = "final pdf = pw.Document();"
    new_pdf_init = """final pdf = pw.Document();
      pw.MemoryImage? logoImage;
      try {
        final logoBytes = await rootBundle.load('assets/eltrive_logo.jpg');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (e) {
        print("Logo load error: $e");
      }"""
    if old_pdf_init in content and "logoImage = pw.MemoryImage(" not in content:
        content = content.replace(old_pdf_init, new_pdf_init)
        modified = True
        
    # 3. Replace Header
    # Pattern A: pw.Header(level: 0, child: pw.Text("...", style: ...))
    header_match = re.search(r'pw\.Header\(\s*level:\s*0,\s*child:\s*pw\.Text\(\s*"([^"]+)"\s*,\s*style:\s*pw\.TextStyle\([^)]*\)\s*\)\s*\)', content)
    if header_match:
        original_text = header_match.group(1)
        # Remove existing 'ELTRIVE ' if already exists
        clean_text = original_text.replace("ELTRIVE ", "")
        new_text = f"ELTRIVE {clean_text.upper()}"
        replacement = f"""pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("{new_text}", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              if (logoImage != null)
                pw.Image(logoImage, width: 40, height: 40),
            ],
          )"""
        content = content.replace(header_match.group(0), replacement)
        modified = True
    else:
        # Pattern B: pw.Text("...", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))
        # Make the title matcher simpler and wider
        text_header_match = re.search(r'pw\.Text\(\s*"([^"]+)"\s*,\s*style:\s*pw\.TextStyle\(\s*fontSize:\s*20\s*,\s*fontWeight:\s*pw\.FontWeight\.bold\s*\)\s*\)', content)
        if text_header_match:
            original_text = text_header_match.group(1)
            clean_text = original_text.replace("ELTRIVE ", "")
            new_text = f"ELTRIVE {clean_text.upper()}"
            replacement = f"""pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("{new_text}", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                if (logoImage != null)
                  pw.Image(logoImage, width: 50, height: 50),
              ],
            )"""
            content = content.replace(text_header_match.group(0), replacement)
            modified = True
            
    # 4. Fix Summary alignment if present
    old_summary_col = """pw.Column(
              children: dataMap.entries.map((e) => pw.Text("${e.key}: ${e.value.length}")).toList(),
            )"""
    new_summary_col = """pw.SizedBox(height: 5),
            pw.Column(
              children: dataMap.entries.map((e) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 180,
                        child: pw.Text("${e.key}:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Text("${e.value.length}"),
                    ],
                  ),
                );
              }).toList(),
            )"""
            
    if old_summary_col in content:
        content = content.replace(old_summary_col, new_summary_col)
        modified = True
        
    if modified:
        return content
    return None

for path in reports:
    try:
        updated = brand_file(path)
        if updated is not None:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(updated)
            print(f"Successfully branded report PDF in {os.path.relpath(path, lib_dir)}")
    except Exception as e:
        print(f"Error processing {path}: {e}")

print("Completed branding for all safety module reports!")
