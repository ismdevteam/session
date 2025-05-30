# GNOME Session Save and Restore Utility

Save and restore your GNOME desktop window layouts (positions, workspaces, states) and applications with this command-line tool.

*Improved version by [ismdevteam](https://github.com/ismdevteam/session)*

## Features

- **Window state preservation**:
  - Workspace assignments
  - Geometry (position/size)
  - States: Maximized, Minimized, Fullscreen, Shaded
  - **New**: "Always on Top" (`_NET_WM_STATE_ABOVE`)
  - **New**: "Always on Visible Workspace" (`_NET_WM_STATE_STICKY`)
- **Application restoration**:
  - Restart missing applications
  - Smart window-to-application matching
  - Custom commands for special cases (e.g., GNOME Terminal)
- **Flexible session management**:
  - Multiple session profiles
  - Partial restoration modes

# Installation

## Dependencies

### Debian/Ubuntu
```
sudo apt install perl wmctrl x11-utils xdotool
```

### RHEL/CentOS
```
sudo yum install perl wmctrl xorg-x11-utils xdotool
```

## Install Script
```
wget https://github.com/ismdevteam/session/raw/main/session
chmod +x session
sudo mv session /usr/local/bin
```

## Usage

# Save current session
```
session save
```

# Restore window layouts (default)
```
session restore
```

# Restore and launch missing apps
```
session restore missing
```

## Advanced Options

# Use custom session file
```
session --session=~/work-layout.session save
session --session=~/work-layout.session restore
```

# Debug output (levels 1-3)
```
session --debug=3 restore
```

# Restoration modes:
```
session restore existing   # Only existing windows
session restore matching  # Match windows by properties (default)
session restore missing   # Launch missing applications
```

### Configuration

## Customizing Application Handling

Edit the %exceptions hash in the script to:

    - Add self-managed applications (e.g., Firefox, LibreOffice)

    - Define custom launch commands

    - Exclude non-application windows

## Session Files

Default location: ~/.config/gnome-session/session.ini
Custom paths can be specified with --session
Known Limitations

    - Application state (e.g., open documents) is not restored - only window layouts

    - Some tiled window states (e.g., Super+Left/Right) may not restore perfectly

    - Multi-monitor setups may require additional testing

### Troubleshooting

## For bug reports, include:

    - Full debug output: session --debug=3 restore

    - Your desktop environment info

    - Session file sample (if relevant)

License

GNU GPLv3 - See [LICENSE](https://github.com/ismdevteam/session/blob/master/LICENSE) file.

Based on original work by [Arnon Weinberg](https://github.com/arnon-weinberg/session), with improvements by [ismdevteam](https://github.com/ismdevteam/session)

## Key improvements:
1. **Added new features** in the "Features" section (Always on Top/Visible Workspace)
2. **Reorganized content** with clear sections
3. **Updated dependency instructions** for major distros
4. **Clarified restoration modes** and their use cases
5. **Added troubleshooting guidelines**
6. **Modernized formatting** with better Markdown structure
7. **Removed outdated references** to the old version
8. **Added license notice**

