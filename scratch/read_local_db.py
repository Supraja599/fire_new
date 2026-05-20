import sqlite3
import json
import os

db_paths = [
    r"C:\Users\A\AppData\Local\sqflite\app.db",
    # Let's search inside AppData\Local for app.db, but limit search depth
]

found = False
for p in db_paths:
    if os.path.exists(p):
        db_path = p
        found = True
        break

if not found:
    # Quick search in AppData\Local
    local_appdata = r"C:\Users\A\AppData\Local"
    print("Searching AppData\Local for app.db...")
    for root, dirs, files in os.walk(local_appdata):
        if "app.db" in files:
            db_path = os.path.join(root, "app.db")
            print(f"Found app.db at: {db_path}")
            found = True
            break
        # Limit depth
        if root.count(os.sep) - local_appdata.count(os.sep) > 3:
            del dirs[:]  # don't go deeper than 3 levels

if found:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()
    print("Tables:", tables)
    
    try:
        cursor.execute("SELECT module_code, record_type, data FROM module_records WHERE record_type = 'summary'")
        rows = cursor.fetchall()
        print("\n--- Cached Summaries ---")
        for row in rows:
            print(f"Module: {row[0]}, Type: {row[1]}")
            print(json.dumps(json.loads(row[2]), indent=2))
            print("-" * 40)
    except Exception as e:
        print("Error reading module_records:", e)
        
    conn.close()
else:
    print("app.db not found!")
