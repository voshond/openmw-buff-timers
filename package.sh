#!/bin/bash

# Default version
version="1.0.0"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            version="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-v|--version <version>]"
            exit 1
            ;;
    esac
done

# Set paths
source_dir=$(pwd)
output_dir="$source_dir/dist"
package_name="openmw-bufftimers-v$version"
package_dir="$output_dir/$package_name"
zip_file="$output_dir/$package_name.zip"

# Create output directories
echo "Creating package directories..."
if [ -d "$output_dir" ]; then
    rm -rf "$output_dir"
fi
mkdir -p "$output_dir"
mkdir -p "$package_dir"

# Define files/directories to include
includes=(
    "scripts/bufftimers"
    "textures"
    "bufftimers.omwscripts"
)

# Define files/directories to exclude (for reference, not used in this simple version)
excludes=(
    "scripts/Example"
    "Sample Projects"
    ".cursorrules"
    "debug.ps1"
    ".git"
    ".gitattributes"
    "dist"
    "package.ps1"
    "README.md"
    "CHANGELOG.md"
    "LICENSE"
)

# Copy files to package directory
echo "Copying files to package directory..."
for item in "${includes[@]}"; do
    source_path="$source_dir/$item"
    destination="$package_dir/$item"
    
    # Create destination directory if it doesn't exist
    destination_dir=$(dirname "$destination")
    mkdir -p "$destination_dir"
    
    # Copy the item
    if [ -d "$source_path" ]; then
        # If it's a directory, copy it recursively
        cp -r "$source_path" "$destination"
    elif [ -f "$source_path" ]; then
        # If it's a file, copy it
        cp "$source_path" "$destination"
    else
        echo "Warning: $source_path does not exist, skipping..."
    fi
done

# Create zip file
echo "Creating zip archive: $zip_file"
if [ -f "$zip_file" ]; then
    rm -f "$zip_file"
fi

# Check if zip command is available
if command -v zip &> /dev/null; then
    cd "$output_dir"
    zip -r "$package_name.zip" "$package_name"
    cd "$source_dir"
else
    echo "Error: zip command not found. Please install zip utility."
    exit 1
fi

echo "Package created successfully at: $zip_file"
echo "Files are also available in: $package_dir" 