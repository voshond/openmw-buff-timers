#!/bin/bash

# Parse command line arguments
NOLOG=false
FOCUS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -noLog)
            NOLOG=true
            shift
            ;;
        -focus)
            FOCUS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Clear the console
clear

# Print header
echo "BUFF TIMERS DEBUG (Linux)"

# Set up directories
SOURCE_DIR="$(pwd)"
MOD_DIR="/home/voshond/Documents/Morrowind/mods/openmw-buff-timers"
SCRIPTS_DIR="$MOD_DIR/scripts/bufftimers"
TEXTURES_DIR="$MOD_DIR/textures"

# Create target directories if they don't exist
if [ ! -d "$MOD_DIR" ]; then
    mkdir -p "$MOD_DIR"
    echo "Created mod directory: $MOD_DIR"
fi

if [ ! -d "$SCRIPTS_DIR" ]; then
    mkdir -p "$SCRIPTS_DIR"
    echo "Created scripts directory: $SCRIPTS_DIR"
fi

if [ ! -d "$TEXTURES_DIR" ]; then
    mkdir -p "$TEXTURES_DIR"
    echo "Created textures directory: $TEXTURES_DIR"
fi

# Clean directories before copying to ensure a clean state
if [ -d "$SCRIPTS_DIR" ]; then
    rm -rf "$SCRIPTS_DIR"/*
    echo "Cleaned scripts directory"
fi

if [ -d "$TEXTURES_DIR" ]; then
    rm -rf "$TEXTURES_DIR"/*
    echo "Cleaned textures directory"
fi

# Copy all relevant files
cp -r "$SOURCE_DIR/scripts/bufftimers/"* "$SCRIPTS_DIR/"
cp -r "$SOURCE_DIR/textures/"* "$TEXTURES_DIR/"
cp "$SOURCE_DIR/bufftimers.omwscripts" "$MOD_DIR/"
echo "Copied all mod files to $MOD_DIR"

# Check if OpenMW is running (both native and Flatpak)
OPENMW_PID=$(pgrep -f "openmw")
FLATPAK_OPENMW_PID=$(pgrep -f "org.openmw.OpenMW")

if [ "$FOCUS" = true ]; then
    if [ -n "$OPENMW_PID" ] || [ -n "$FLATPAK_OPENMW_PID" ]; then
        echo "OpenMW is running, attempting to focus window..."
        
        # Try to focus the OpenMW window using wmctrl if available
        if command -v wmctrl &> /dev/null; then
            wmctrl -a "OpenMW" 2>/dev/null || wmctrl -a "openmw" 2>/dev/null
            echo "Attempted to focus OpenMW window using wmctrl"
        else
            echo "wmctrl not available, cannot focus window automatically"
            echo "Please manually switch to the OpenMW window"
        fi
    else
        echo "OpenMW is not running. Starting OpenMW Flatpak..."
        
        # Try to start OpenMW Flatpak
        if command -v flatpak &> /dev/null; then
            echo "Starting OpenMW via Flatpak..."
            flatpak run org.openmw.OpenMW &
            echo "OpenMW Flatpak started. Please load your save and enable the mod."
        else
            echo "Flatpak not available. Please start OpenMW manually."
        fi
    fi
elif [ "$FOCUS" = false ]; then
    # Kill OpenMW if running (both native and Flatpak)
    if [ -n "$OPENMW_PID" ]; then
        echo "Terminating native OpenMW process (PID: $OPENMW_PID)..."
        kill "$OPENMW_PID"
        sleep 1
        
        # Force kill if still running
        if pgrep -f "openmw" > /dev/null; then
            echo "Force killing native OpenMW..."
            pkill -9 -f "openmw"
        fi
    fi
    
    if [ -n "$FLATPAK_OPENMW_PID" ]; then
        echo "Terminating Flatpak OpenMW process (PID: $FLATPAK_OPENMW_PID)..."
        kill "$FLATPAK_OPENMW_PID"
        sleep 1
        
        # Force kill if still running
        if pgrep -f "org.openmw.OpenMW" > /dev/null; then
            echo "Force killing Flatpak OpenMW..."
            pkill -9 -f "org.openmw.OpenMW"
        fi
    fi
    
    # Start OpenMW Flatpak
    if command -v flatpak &> /dev/null; then
        echo "Starting OpenMW via Flatpak..."
        flatpak run org.openmw.OpenMW &
        echo "OpenMW Flatpak started. Please load your save and enable the mod."
    else
        echo "Flatpak not available. Please start OpenMW manually."
    fi
fi

echo ""
echo "Mod files have been copied to: $MOD_DIR"
echo ""
echo "To use this mod:"
echo "1. Add the mod directory to your OpenMW data paths in openmw.cfg"
echo "2. Add 'content=bufftimers.omwscripts' to your openmw.cfg"
echo "3. Start OpenMW and load a save with some active spell effects"
echo "4. Check the top-right corner for buff/debuff icons"
echo "5. Enable debug logging in mod settings to see console output"
echo ""
