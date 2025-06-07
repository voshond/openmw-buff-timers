#!/bin/bash

# Initialize variables
version=""
message=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            version="$2"
            shift 2
            ;;
        -m|--message)
            message="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-v|--version <version>] [-m|--message <message>]"
            echo "  -v, --version    Version number (format: x.y.z)"
            echo "  -m, --message    Release notes message"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-v|--version <version>] [-m|--message <message>]"
            exit 1
            ;;
    esac
done

# Clear the console
clear

# Function to validate version format
validate_version() {
    local ver="$1"
    if [[ $ver =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Check Git is installed
if ! command -v git &> /dev/null; then
    echo -e "\033[31mError: Git is not installed or not in the PATH.\033[0m"
    exit 1
fi

git_version=$(git --version)
echo "Found Git: $git_version"

# Check for uncommitted changes
status=$(git status --porcelain)
if [ -n "$status" ]; then
    echo -e "\033[31mError: You have uncommitted changes. Commit or stash them before creating a release.\033[0m"
    echo "Uncommitted changes:"
    echo "$status"
    exit 1
fi

# Ask for version number if not provided or invalid
while [ -z "$version" ] || ! validate_version "$version"; do
    read -p "Enter version number (format: x.y.z): " version
done

# Confirm with user
echo -e "\033[36mCreating release v$version\033[0m"

# Check if tag already exists
if git tag -l "v$version" | grep -q "v$version"; then
    echo -e "\033[31mError: Tag v$version already exists.\033[0m"
    exit 1
fi

# Ask for release notes if not provided
if [ -z "$message" ]; then
    read -p "Enter release notes (or press Enter to skip): " message
fi

# Update CHANGELOG.md
changelog_path="$(dirname "$0")/CHANGELOG.md"
if [ -f "$changelog_path" ]; then
    changelog_content=$(cat "$changelog_path")
    release_header="## Version $version"
    
    # Check if version already exists in changelog
    if echo "$changelog_content" | grep -q "## Version $version"; then
        echo -e "\033[33mWarning: Version $version already exists in CHANGELOG.md\033[0m"
    else
        # Add new version with timestamp
        date=$(date +"%Y-%m-%d")
        new_entry="$release_header ($date)\n\n"
        if [ -n "$message" ]; then
            new_entry+="$message\n\n"
        fi
        
        # Insert after first line
        first_line=$(head -n 1 "$changelog_path")
        rest_of_file=$(tail -n +2 "$changelog_path")
        
        # Create updated changelog
        {
            echo "$first_line"
            echo ""
            echo -e "$new_entry"
            echo "$rest_of_file"
        } > "$changelog_path.tmp"
        
        mv "$changelog_path.tmp" "$changelog_path"
        echo -e "\033[32mUpdated CHANGELOG.md with new version information\033[0m"
        
        # Commit changelog changes
        git add "$changelog_path"
        git commit -m "Update CHANGELOG for v$version"
        echo -e "\033[32mCommitted changelog changes\033[0m"
    fi
fi

# Package the mod
echo -e "\033[36mPackaging the mod...\033[0m"
script_dir="$(dirname "$0")"
if [ -f "$script_dir/package.sh" ]; then
    bash "$script_dir/package.sh" --version "$version"
else
    echo -e "\033[33mWarning: package.sh not found, skipping packaging step\033[0m"
fi

# Create and push Git tag
tag_message="Release v$version"
if [ -n "$message" ]; then
    tag_message="$tag_message

$message"
fi

echo -e "\033[36mCreating Git tag v$version...\033[0m"
git tag -a "v$version" -m "$tag_message"

echo -e "\033[36mPushing changes and tag to remote repository...\033[0m"
git push
git push origin "v$version"

echo -e "\033[32mDeploy completed successfully!\033[0m"
echo -e "\033[36mGitHub Actions workflow will now create the release automatically.\033[0m"
echo -e "\033[36mCheck the progress at: https://github.com/voshond/openmw-buff-timers/actions\033[0m" 