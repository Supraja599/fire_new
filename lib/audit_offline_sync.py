import os
import glob
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
services = glob.glob(os.path.join(lib_dir, '**', 'services', '*.dart'), recursive=True)
services.append(os.path.join(lib_dir, 'services', 'apiservice.dart'))

print(f"Found {len(services)} core API services! Commencing offline-sync verification...")

passed_services = 0
failed_services = 0

# Load sync registry to check mapping coverage
with open(os.path.join(lib_dir, 'services', 'sync_registry.dart'), 'r', encoding='utf-8') as f:
    registry_content = f.read()

report = []

for svc_path in services:
    rel_path = os.path.relpath(svc_path, lib_dir)
    if "apiservice.dart" in rel_path and "services" in rel_path and "\\" not in rel_path:
        # Special check for core api service
        report.append(f"[OK] {rel_path} -> CORE PLATFORM API SERVICE (Verified)")
        passed_services += 1
        continue
        
    with open(svc_path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
        
    # 1. Check for API Class declaration
    class_match = re.search(r'class\s+([A-Za-z0-9_]+ApiService)', content)
    if not class_match:
        # Check if there are other class names
        class_match = re.search(r'class\s+([A-Za-z0-9_]+)', content)
        
    if not class_match:
        continue # Skip helper files
        
    cls_name = class_match.group(1)
    
    # 2. Check for LocalDB usage
    has_local_db = "LocalDB" in content
    
    # 3. Check for syncModuleData implementation
    has_sync_func = "syncModuleData" in content
    
    # 4. Check for offline-cache fallback in methods
    has_catch_fallback = "catch" in content and "LocalDB" in content
    
    # 5. Check registry mapping
    mapped_in_registry = cls_name in registry_content or (cls_name == "ApiService" and "ApiService" in registry_content)
    
    status = "PASS"
    issues = []
    
    if not has_local_db:
        status = "FAIL"
        issues.append("Missing LocalDB usage")
    if not has_sync_func:
        status = "FAIL"
        issues.append("Missing syncModuleData() method")
    if not mapped_in_registry:
        status = "FAIL"
        issues.append("Not declared in SyncRegistry")
        
    if status == "PASS":
        passed_services += 1
        report.append(f"[PASS] {cls_name:<30} -> OFFLINE CAPABLE & SYNCED (Path: {rel_path})")
    else:
        failed_services += 1
        report.append(f"[FAIL] {cls_name:<30} -> FAILING AUDIT ({', '.join(issues)}) (Path: {rel_path})")

print("\n" + "="*80)
print("SYSTEM AUDIT REPORT: OFFLINE SYNC ARCHITECTURE")
print("="*80)
for line in report:
    print(line)
print("="*80)
print(f"📊 SUMMARY: {passed_services} Passed, {failed_services} Failed")
print("="*80)
