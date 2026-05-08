import os

lib_dir = r"c:\Users\A\AndroidStudioProjects\Fire_New\lib"

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            file_path = os.path.join(root, file)
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            if ");;;" in content or ");;" in content:
                print(f"Cleaning semicolons in {file_path}...")
                new_content = content.replace(");;;", ");").replace(");;", ");")
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(new_content)

print("Semicolon cleanup complete.")
