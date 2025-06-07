# OpenMW Buff Timers - Requirements Document

## Project Overview

Create a modern buff timer system for OpenMW that displays active spell effects with visual cooldown indicators in a clean, fixed position interface. This implementation combines the best elements from existing projects while eliminating complexity around draggable UI elements.

## Core Requirements

### Visual Design

-   **Fixed Position**: Top right corner of screen (no configuration needed)
-   **Growth Direction**: Icons grow from right to left (newest buffs appear rightmost)
-   **Icon Style**: Use voshondsQuickSelect icon rendering approach for professional appearance
-   **Cooldown Visualization**: Implement radial swipe animation from bufftimers radialSwipe.lua
-   **Time Display**: Show remaining time with consolidation (>60s displays as "Xm")

### Functional Requirements

-   Display all active buffs/debuffs with duration timers
-   Real-time updates of remaining time
-   Radial swipe overlay indicating time remaining
-   Proper buff/debuff categorization
-   Settings system for customization
-   Debug logging system for troubleshooting

## Technical Architecture

### Core Components

#### 1. Main Player Script (`bt_player.lua`)

-   Primary entry point and UI management
-   Buff/debuff detection and tracking
-   UI update timer management
-   Integration point for all modules

#### 2. Icon Rendering System (`bt_icon_render.lua`)

**Based on**: `voshondsQuickSelect/ci_icon_render.lua`

-   Professional icon styling and rendering
-   Text overlay management (time display)
-   Color coding for different buff types
-   Icon sizing and opacity management

#### 3. Radial Swipe System (`bt_radial_swipe.lua`)

**Based on**: `bufftimers/radialSwipe.lua`

-   Atlas-based radial animation for cooldown visualization
-   Texture management for swipe effects
-   Integration with buff duration data

#### 4. Settings System (`bt_settings.lua`)

**Based on**: `voshondsQuickSelect/qs_settings.lua`

-   Comprehensive configuration options
-   Multiple setting categories (UI, Text, Debug)
-   Persistent storage management

#### 5. Debug System (`bt_debug.lua`)

**Based on**: `voshondsQuickSelect/qs_debug.lua`

-   Centralized logging functionality
-   Configurable debug levels
-   Performance monitoring capabilities

#### 6. Utility Functions (`bt_utility.lua`)

-   Time formatting functions
-   Buff/debuff categorization
-   Common helper functions

### File Structure

```
scripts/
└── bufftimers/
    ├── bt_player.lua          # Main player script
    ├── bt_icon_render.lua     # Icon rendering system
    ├── bt_radial_swipe.lua    # Radial swipe animations
    ├── bt_settings.lua        # Settings management
    ├── bt_debug.lua           # Debug logging
    ├── bt_utility.lua         # Utility functions
    └── bt_modinfo.lua         # Mod information
```

## Implementation Details

### UI Positioning

-   **Anchor Point**: Top-right corner of screen
-   **Layout**: Horizontal flex container
-   **Direction**: Right-to-left growth (newest buffs on right)
-   **No Dragging**: Fixed position, no user repositioning
-   **No Position Storage**: Eliminates complex state management

### Icon Rendering

**From ci_icon_render.lua approach:**

-   Icon size configuration
-   Text overlay for remaining time
-   Shadow effects for readability
-   Color coding based on buff type
-   Opacity management for expiring buffs

### Radial Swipe Implementation

**From radialSwipe.lua approach:**

-   4096x4096 atlas texture with 360 frames (20x20 grid)
-   Each frame represents 1 degree of completion
-   Dynamic texture offset calculation based on remaining time
-   Support for "Shade" and "Unshade" modes

### Time Formatting

**From voshondsQuickSelect time formatting:**

-   Times >3600s: Display as "Xh" (hours)
-   Times >60s: Display as "Xm" (minutes)
-   Times >10s: Display as "Xs" (seconds)
-   Times ≤10s: Display as "X.Xs" (decimal seconds)

### Settings Categories

#### Main Settings

-   Icon size (20-100 pixels)
-   Update frequency
-   Enable/disable mod
-   Debug logging levels

#### Text Appearance

-   Text color and opacity
-   Shadow effects
-   Font sizes
-   Show/hide time display

#### Visual Effects

-   Radial swipe mode (Shade/Unshade)
-   Icon opacity for expiring buffs
-   Animation speed

#### Debug Options

-   Enable debug logging
-   Enable frame logging
-   Performance monitoring

### Buff/Debuff Detection

**From bufftimers common.lua approach:**

-   Use OpenMW Actor.activeSpells() API
-   Categorize effects as buffs vs debuffs
-   Filter for effects with duration timers
-   Track effect magnitude and affected attributes/skills

### Update System

-   Timer-based updates (configurable frequency)
-   Efficient UI refresh only when needed
-   Proper cleanup of expired effects
-   Memory management for long play sessions

## Key Differences from Source Projects

### Simplified from bufftimers

-   **Removed**: Draggable UI elements
-   **Removed**: Position storage and persistence
-   **Removed**: Complex mouse event handling
-   **Removed**: Multiple hotbar support
-   **Simplified**: Fixed positioning logic

### Enhanced from voshondsQuickSelect

-   **Added**: Radial swipe cooldown visualization
-   **Added**: Buff/debuff specific functionality
-   **Focused**: Spell effects instead of inventory items
-   **Simplified**: No enchantment charge tracking needed

## Implementation Phases

### Phase 1: Core Foundation

1. Create basic file structure
2. Implement bt_modinfo.lua and bt_settings.lua
3. Set up bt_debug.lua logging system
4. Create bt_utility.lua with time formatting

### Phase 2: Buff Detection

1. Implement buff/debuff detection in bt_player.lua
2. Create categorization system
3. Set up basic UI container (fixed top-right)
4. Test buff detection and basic display

### Phase 3: Icon Rendering

1. Implement bt_icon_render.lua based on ci_icon_render.lua
2. Add text overlay system for time display
3. Implement color coding and styling
4. Test icon appearance and text rendering

### Phase 4: Radial Swipe

1. Implement bt_radial_swipe.lua based on radialSwipe.lua
2. Create texture atlas system
3. Add animation calculations
4. Integrate with icon rendering system

### Phase 5: Polish & Testing

1. Performance optimization
2. Settings integration and testing
3. Debug system validation
4. Final UI polish and edge case handling

## Success Criteria

-   Buffs display in top-right corner with professional appearance
-   Radial swipe accurately represents remaining time
-   Time formatting matches specification (>60s as "Xm")
-   Settings system provides adequate customization
-   Debug system enables effective troubleshooting
-   Performance impact is minimal during normal gameplay
-   No UI positioning bugs or state management issues

## Technical Notes

-   Use OpenMW Lua scripting API
-   Follow existing project patterns for consistency
-   Maintain compatibility with OpenMW 0.48+
-   Ensure proper memory management
-   Use efficient update patterns to minimize performance impact
