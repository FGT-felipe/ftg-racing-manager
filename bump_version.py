import sys
import re
import os

def bump_version(new_version):
    pubspec_path = 'pubspec.yaml'
    
    if not os.path.exists(pubspec_path):
        print("Error: pubspec.yaml not found in current directory.")
        return

    with open(pubspec_path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    match = re.search(r'^version:\s*([0-9\.]+)(?:\+([0-9]+))?', content, re.MULTILINE)
    
    if match:
        build_number = match.group(2)
        new_build_number = int(build_number) + 1 if build_number else 1
        new_version_str = f"version: {new_version}+{new_build_number}"
        content = re.sub(r'^version:\s*.*$', new_version_str, content, flags=re.MULTILINE)
        
        with open(pubspec_path, 'w', encoding='utf-8', newline='\n') as file:
            file.write(content)
        print(f"✅ Bumped pubspec.yaml to {new_version}+{new_build_number}")
    else:
        print("❌ Could not find version in pubspec.yaml")

    # Update in game_universe_model.dart
    universe_model_path = 'lib/models/domain/game_universe_model.dart'
    if os.path.exists(universe_model_path):
        with open(universe_model_path, 'r', encoding='utf-8') as file:
            content = file.read()
        content = re.sub(
            r"gameVersion:\s*map\['gameVersion'\]\s*\?\?\s*'[^']+'",
            f"gameVersion: map['gameVersion'] ?? '{new_version}'",
            content
        )
        with open(universe_model_path, 'w', encoding='utf-8', newline='\n') as file:
            file.write(content)
        print(f"✅ Bumped game_universe_model.dart to {new_version}")

    # Update in ARB files
    arb_dir = 'lib/l10n'
    for arb_file in ['app_en.arb', 'app_es.arb']:
        arb_path = os.path.join(arb_dir, arb_file)
        if os.path.exists(arb_path):
            with open(arb_path, 'r', encoding='utf-8') as file:
                content = file.read()
            content = re.sub(
                r'"versionFooter":\s*"V[0-9\.]+ - Fire Tower Games Studio"',
                f'"versionFooter": "V{new_version} - Fire Tower Games Studio"',
                content
            )
            with open(arb_path, 'w', encoding='utf-8', newline='\n') as file:
                file.write(content)
            print(f"✅ Bumped {arb_file} to V{new_version}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python bump_version.py <new_version>")
        sys.exit(1)
    bump_version(sys.argv[1])
