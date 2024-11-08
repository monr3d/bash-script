#!/bin/bash

# scroll_output - Execute a command and scroll its output
    #
    # Parameters:
    #   command - The command to execute
    #   visible_lines - The number of lines to show at a time (default: 10)
    #   indent - The indentation for the output (default: " > ")
    #
    # Description:
    #   This function will execute a command, scroll its output and pause at the end.
    #   It will show the last 10 lines of the output (or the number of lines specified
    #   by the visible_lines parameter) and then wait 15 seconds or until Enter is pressed.
    #
# Needed to reenable echo of keystrok in case of exiting the script early or on error
trap 'stty echo icanon' EXIT

scroll_output() {
    local command="$1"
    local visible_lines="${2:-10}"  # Number of lines to show at a time, default to 10
    local term_width=$(stty size | cut -d' ' -f2)  # Get the terminal width
    local indent=${3:-" $RT "}            # Indentation for the output
    local buffer=()
    
    for ((i = 0; i < visible_lines; i++)); do
        buffer+=("")
    done
    
    # Clear the line
    printf "\r%b" "\e[2K"
    
    # Save the cursor position
    printf "\e[s"
    
    # Move cursor down by number of lines
    printf "\e[%sB" "${visible_lines}"

    # Disable display of keystroke
    stty -echo -icanon
    
    # Execute the command and scroll the output
    while IFS= read -r line; do
        
        line="$(printf "%s%s\n" "$indent" "$line")"
        
        # Truncate the line to fit the terminal width
        if [ "$(printf "%b" "$line" | wc -c)" -gt "$term_width" ]; then
            line="${line:0:$((term_width))}"
            line+=" >..."
        fi
        
        # Add the new line to the buffer
        buffer+=("$line")
        
        # Remove the first line from the buffer
        buffer=("${buffer[@]:1}")
        
        # Move cursor to the saved position
        printf "\e[u"
        #printf "\e[%dA" "${#buffer[@]}"
        
        # Print the updated buffer
        printf "%b\n" "${buffer[@]}"

        # Pause to create the illusion of scrolling
        sleep 0.1
        
    done < <(eval "$command")

    # Enable echoing of keystroke
    stty echo icanon
    
    # Catch any key press made during output
    read -t 0.1 -s -r 2>/dev/null || true
    
    # Wait for 15 seconds or until Enter is pressed
    for ((i = 15; i > 0; i--)); do
        printf "\rPress any key to continue or wait %d seconds..." "$i"
        if read -t 1 -n 1 -s; then
            break
        fi
    done
    
    # Restore the cursor position
    printf "\e[u"
    
    # Clear the line below the cursor
    printf "\e[J"
}
