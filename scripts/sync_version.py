import re
import sys
import os

def update_cargo_toml(path, version):
    with open(path, 'r') as f:
        content = f.read()
    new_content = re.sub(r'(^version\s*=\s*")[^"]+(")', fr'\g<1>{version}\g<2>', content, flags=re.MULTILINE)
    with open(path, 'w') as f:
        f.write(new_content)
    print(f"Updated {path} to {version}")

def update_pubspec_yaml(path, version):
    with open(path, 'r') as f:
        content = f.read()
    # Flutter version is usually version: 1.0.0+1
    new_content = re.sub(r'(^version:\s*)[^\+]+(\+.*)?', fr'\g<1>{version}\g<2>', content, flags=re.MULTILINE)
    with open(path, 'w') as f:
        f.write(new_content)
    print(f"Updated {path} to {version}")

def update_changelog(path, version, date):
    with open(path, 'r') as f:
        lines = f.readlines()
    
    new_lines = []
    found_unreleased = False
    for line in lines:
        if line.startswith('## [Unreleased]'):
            new_lines.append(f'## [{version}] - {date}\n')
            found_unreleased = True
        else:
            new_lines.append(line)
            
    if not found_unreleased:
        # If no [Unreleased], find the first version header and insert above it
        inserted = False
        final_lines = []
        for line in new_lines:
            if not inserted and line.startswith('## ['):
                final_lines.append(f'## [{version}] - {date}\n\n')
                inserted = True
            final_lines.append(line)
        new_lines = final_lines

    with open(path, 'w') as f:
        f.writelines(new_lines)
    print(f"Updated {path} to {version}")

def update_version_file(path, version):
    with open(path, 'w') as f:
        f.write(version + '\n')
    print(f"Updated {path} to {version}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python sync_version.py <version> <date> [root_dir]")
        sys.exit(1)
    
    version = sys.argv[1]
    date = sys.argv[2]
    root_dir = sys.argv[3] if len(sys.argv) > 3 else "."

    version_file_path = os.path.join(root_dir, "VERSION")
    cargo_path = os.path.join(root_dir, "backend/Cargo.toml")
    pubspec_path = os.path.join(root_dir, "frontend/pubspec.yaml")
    changelog_path = os.path.join(root_dir, "CHANGELOG.md")

    if os.path.exists(version_file_path):
        update_version_file(version_file_path, version)
    if os.path.exists(cargo_path):
        update_cargo_toml(cargo_path, version)
    if os.path.exists(pubspec_path):
        update_pubspec_yaml(pubspec_path, version)
    if os.path.exists(changelog_path):
        update_changelog(changelog_path, version, date)
