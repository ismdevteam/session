#!/bin/bash
# Open applications: terminal, nautilus (with 2 tabs), firefox and gedit and then restore their positions on Debian 11 gnome using session script

# If running from terminal, re-launch detached
if [ -t 0 ]; then
    echo "Detaching from terminal..."
    setsid "$0" "$@" >/dev/null 2>&1 &
    exit 0
fi

set -e

# Check if script is running from a terminal
RUNNING_IN_TERMINAL=false
if [ -t 0 ]; then
    RUNNING_IN_TERMINAL=true
    PARENT_TERMINAL_ID=$(ps -o ppid= -p $$ | xargs)
    PARENT_TERMINAL_CMD=$(ps -o cmd= -p $PARENT_TERMINAL_ID)
fi

# Check for existence of recovery session file
SESSION_FILE="$HOME/restore.session"
ls -l "$SESSION_FILE" >/dev/null || ( 
    notify-send --urgency=critical \
                --icon=dialog-error \
                "Session Restore Error" \
                "File $SESSION_FILE not found! Cannot restore session."
    exit 1
)

# Check for existence of session script file
SESSION_SCRIPT="$(dirname "$0")/session"
ls -l "$SESSION_SCRIPT" >/dev/null || (
    notify-send --urgency=critical \
                --icon=dialog-error \
                "Session Script Error" \
                "File $SESSION_SCRIPT not found! Cannot restore session."
    exit 1
)


# Check for required commands
check_dependencies() {
    local missing=0

    if ! command -v xdotool >/dev/null 2>&1; then
        echo "Error: xdotool is not installed."
        missing=1
    fi

    if ! command -v wmctrl >/dev/null 2>&1; then
        echo "Error: wmctrl is not installed."
        missing=1
    fi

    if ! command -v notify-send >/dev/null 2>&1; then
        echo "Error: notify-send is not installed."
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        echo "Please install missing dependencies with:"
        echo "sudo apt-get -y install xdotool wmctrl libnotify-bin"
        exit 1
    fi
}

# Run dependency check
check_dependencies

set +e

# List of terminal classes to preserve (all lowercase)
TERMINAL_CLASSES="gnome-terminal xterm uxterm konsole terminator tilix st"

window_ids=$(wmctrl -l | awk '{print $1}')
for window in $window_ids; do
    # Get window class (convert to lowercase for comparison)
    window_class=$(xprop -id "$window" WM_CLASS 2>/dev/null | awk -F '"' '{print $4}' | tr '[:upper:]' '[:lower:]')
    
    # Check if window is a terminal we want to preserve
    skip_window=false
    for term_class in $TERMINAL_CLASSES; do
        if [[ "$window_class" == *"$term_class"* ]]; then
            skip_window=true
            break
        fi
    done
    
    if ! $skip_window; then
        wmctrl -ic "$window" 2>/dev/null
    fi
done

# Close specific windows with titles matching patterns
close_select_windows() {
    declare -a patterns=(
        "Terminal"
        "Nautilus"
        "Firefox"
        "gedit"
    )

    for pattern in "${patterns[@]}"; do
        wmctrl -l | grep -i "$pattern" | while read -r line; do
            window_id=$(echo "$line" | awk '{print $1}')
            # If running in terminal, don't close the parent terminal window
            if $RUNNING_IN_TERMINAL && [[ "$pattern" == "Terminal" ]]; then
                window_pid=$(xdotool getwindowpid "$window_id" 2>/dev/null)
                if [[ "$window_pid" == "$PARENT_TERMINAL_ID" ]]; then
                    echo "Skipping parent terminal window: $line" >> /tmp/restore_session.log
                    continue
                fi
            fi
            echo "Closing window: $line" >> /tmp/restore_session.log
            wmctrl -i -c "$window_id"
            sleep 0.3
        done
    done
}

# Close existing windows (install notify-send: sudo apt-get -y install libnotify-bin)
notify-send "Session Restore" "Closing existing application windows..." --icon=system-log-out

close_select_windows

# Don't kill parent terminal if running from terminal
if ! $RUNNING_IN_TERMINAL; then
    pkill -f gnome-terminal-server
    pkill -f terminal
fi

killall nautilus 2>/dev/null
pkill -f firefox-esr
killall gedit 2>/dev/null
sleep 2

# Open applications
notify-send "Session Restore" "Opening application windows..." --icon=system-run

# Open terminal (only if not running from terminal or if we want a second instance)
if ! $RUNNING_IN_TERMINAL; then
    gnome-terminal &
    sleep 1
    terminal_window=$(wmctrl -lx | grep gnome-terminal-server.Gnome-terminal | awk '{print $1}' | head -n 1)
else
    terminal_window=$(wmctrl -lx | grep gnome-terminal-server.Gnome-terminal | awk '{print $1}' | head -n 1)
    sleep 1
    # Open second terminal if
    gnome-terminal &
fi

# Get all gnome-terminal window IDs
terminal_windows=($(wmctrl -lx | grep "gnome-terminal-server.Gnome-terminal" | awk '{print $1}'))
terminal_count=$(wmctrl -lx | grep -c "gnome-terminal-server.Gnome-terminal")

echo "Found $terminal_count open terminal(s)"

if [ "$terminal_count" -gt 2 ]; then
    echo "Found $terminal_count terminals. Killing extra ones..."
    # Loop through terminals, keeping first 2, killing the rest
    for ((i=0; i<terminal_count-2; i++)); do
        wmctrl -ic "${terminal_windows[i]}"  # Close gracefully
    done
fi

sleep 1
terminal_count=$(wmctrl -lx | grep -c "gnome-terminal-server.Gnome-terminal")
sleep 1

echo "Found $terminal_count open terminal(s)"
if [ "$terminal_count" -le 1 ]; then
    sleep 1
    echo "Open second terminal"
    # Open second terminal if count is 0 or 1
    gnome-terminal &
fi

# Open Firefox
firefox &
sleep 3

# Unmaximize (remove full-height/snapped state)
wmctrl -r "Mozilla Firefox" -b remove,maximized_vert
wmctrl -r "Mozilla Firefox" -b remove,maximized_horz

# Change width and height of firefox window
wmctrl -r "Mozilla Firefox" -e 0,200,200,640,420 2>/dev/null

# Fallback to xdotool if wmctrl fails
if [ $? -ne 0 ]; then
    FF_WINDOW=$(xdotool search --name "Mozilla Firefox" | head -1)
    xdotool windowsize "$FF_WINDOW" 320 280
    xdotool windowmove "$FF_WINDOW" 100 100
fi

sleep 1

# Open gedit
gedit &
sleep 1

# Unmaximize gedit (removes fullscreen/maximized state)
wmctrl -r "gedit" -b remove,maximized_vert,maximized_horz

# Send Ctrl+T to open new tab
sleep 1
nautilus ~/Downloads &

# Don't wait for Nautilus window to appear and immediately grep its window, otherwise new tab won't be added automatically with ctrl+t
nautilus_window=$(wmctrl -lx | grep org.gnome.Nautilus | awk '{print $1}' | head -n 1)
wmctrl -i -a "$nautilus_window" 2>/dev/null
xdotool key --window "$nautilus_window" ctrl+t
sleep 2
xdotool key --window "$nautilus_window" ctrl+t
xdotool key --window "$nautilus_window" Escape
sleep 0.5
wmctrl -i -a "$terminal_window"

# Run session restore
sleep 3
$SESSION_SCRIPT --session=$SESSION_FILE restore

notify-send "Session Restore" "All applications opened and session restored!" --icon=dialog-information
