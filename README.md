# Voshond's Buff Timers for OpenMW

A modern buff timer system for OpenMW that displays active spell effects with radial swipe cooldown visualization in the top-right corner of your screen.

## Features

- **Visual Buff/Debuff Display**: Shows all active magical effects with custom icons
- **Radial Countdown Timers**: Beautiful radial swipe overlays that show remaining duration
- **Color-Coded Urgency**: Icons change color based on remaining time (green → yellow → red)
- **Customizable Layout**: Icons grow from right to left, with newest effects on the right
- **Configurable Settings**: Extensive in-game settings for size, opacity, update intervals, and more
- **Performance Optimized**: Efficient rendering with configurable update rates
- **Debug Support**: Built-in debugging tools for troubleshooting

## Screenshots

![image](media/screenshot003.png)

## Installation

1. Download the latest release from the releases page
2. Extract the contents to your OpenMW data directory
3. Add `bufftimers.omwscripts` to your load order in the OpenMW Launcher
4. Launch OpenMW and enjoy enhanced spell effect tracking!

## Usage

Once installed, the mod automatically displays active spell effects in the top-right corner of your screen. Each effect shows:

- **Icon**: Visual representation of the spell effect
- **Radial Timer**: Countdown overlay showing remaining duration
- **Time Text**: Numerical time remaining (if enabled)
- **Effect Name**: Abbreviated effect name (if enabled)

## Configuration

Access the settings through OpenMW's in-game settings menu under "voshond's Buff Timers":

### Main Settings

- **Enable Buff Timers**: Master on/off switch
- **Icon Size**: Adjust icon size (16-64 pixels)
- **Update Interval**: Control refresh rate (0.1-2.0 seconds)
- **Enable Radial Countdown**: Toggle radial overlay effects

### Visual Settings

- **Show Time Text**: Display numerical countdown
- **Show Effect Names**: Display abbreviated effect names
- **Text Size**: Customize font sizes for names and timers
- **Radial Opacity**: Control transparency of countdown overlays

### Debug Options

- **Debug Logging**: Enable console debug messages
- **Frame Logging**: Enable verbose frame-by-frame logging

## Requirements

- OpenMW 0.48.0 or later
- Lua scripting support enabled

## Contributing

Contributions are welcome! Feel free to submit pull requests or open issues on the project repository.

## Credits

**Author**: voshond  
**Version**: 1.0.1  
**License**: See LICENSE file

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.
