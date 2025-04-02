# AutoKeybinder

A World of Warcraft addon that automatically sets up keybindings for your character based on CSV configuration files.

## Features

- Supports multiple specializations through CSV configuration
- Slash commands for manual keybinding setup
- Saves bindings to your character's binding set

## Installation

1. Download the addon files
2. Extract them to your World of Warcraft `_retail_/Interface/AddOns` folder
3. Make sure the folder is named `AutoKeybinder`

## Usage

### In-Game UI
Use `/autokb` or `/akb` to open the configuration window. The window includes:
- A text area where you can paste your CSV data
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
R,Demonic Circle
```

### Key Format
- Regular keys: `1`, `2`, `Q`, `E`, etc.
- Modifier keys: `Shift+`, `Ctrl+`, `Alt+`
- Mouse buttons: `Mouse 4`, `Mouse 5`, etc.

## Note

This addon will overwrite any existing keybindings for the supported spells. Make sure to backup your current keybindings if needed. 