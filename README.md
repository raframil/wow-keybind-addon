# AutoKeybinder

A World of Warcraft addon that automatically sets up keybindings for your character based on CSV configuration files.

## Features

- Automatically sets up keybindings when you log in or change specializations
- Supports multiple specializations through CSV configuration
- Slash commands for manual keybinding setup
- Saves bindings to your character's binding set
- Easy configuration through CSV files
- In-game UI for editing and managing bindings

## Installation

1. Download the addon files
2. Extract them to your World of Warcraft `_retail_/Interface/AddOns` folder
3. Make sure the folder is named `AutoKeybinder`

## Usage

### In-Game UI
Use `/autokb config` or `/akb config` to open the configuration window. The window includes:
- A text area where you can paste your CSV data
- Save button to save the current CSV to file
- Load button to load the saved CSV from file
- Apply button to immediately apply the current bindings

### CSV Format
The CSV file should have two columns:
1. Key binding (e.g., "1", "Shift+1", "Ctrl+Q", "Mouse 4")
2. Spell name (e.g., "Incinerate", "Summon Infernal")

Example:
```csv
1,Incinerate
Shift+1,Summon Infernal
Ctrl+Q,Soulstone
Mouse 4,Demonic Circle
```

### Key Format
- Regular keys: `1`, `2`, `Q`, `E`, etc.
- Modifier keys: `Shift+`, `Ctrl+`, `Alt+`
- Mouse buttons: `Mouse 4`, `Mouse 5`, etc.

### Automatic Application
The addon will automatically set up your keybindings when:
- You log into the game
- You change your specialization

### Manual Application
You can also manually trigger the keybinding setup using these slash commands:
- `/autokb` or `/akb` - Applies the current bindings
- `/autokb config` or `/akb config` - Opens the configuration window

## Current Support

Currently supports:
- Warlock: Destruction spec

## Adding More Specializations

To add support for more specializations:
1. Create a new CSV file for the specialization (e.g., `affliction.csv`)
2. Add the appropriate specialization check in the event handler in `AutoKeybinder.lua`

## Note

This addon will overwrite any existing keybindings for the supported spells. Make sure to backup your current keybindings if needed. 