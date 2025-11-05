#!/usr/bin/env bash

# This script provides an interactive menu to apply a NixOS host configuration.
# It must be run with sudo or as the root user.

# --- Sanity Checks ---

# 1. Ensure the script is run as root.
if [[ "$EUID" -ne 0 ]]; then
  echo "Error: Please run this script with sudo or as the root user."
  exit 1
fi

# 2. Determine the script's location to reliably find the 'hosts' directory.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
HOSTS_DIR="$SCRIPT_DIR/hosts"

if [ ! -d "$HOSTS_DIR" ]; then
    echo "Error: The 'hosts' directory was not found at $HOSTS_DIR"
    echo "Please ensure you are running this script from the root of your NixOS configuration repository."
    exit 1
fi

# --- Main Logic ---

# 1. Find all available host configurations by listing subdirectories in 'hosts/'.
#    The results are stored in an array called 'hosts'.
mapfile -t hosts < <(find "$HOSTS_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)

if [ ${#hosts[@]} -eq 0 ]; then
    echo "Error: No host configurations were found in the '$HOSTS_DIR' directory."
    exit 1
fi

# 2. Display the menu of choices to the user.
echo "Please select the NixOS configuration you want to apply:"
for i in "${!hosts[@]}"; do
    # Print each option with a number, starting from 1.
    printf "  %d) %s\n" "$((i+1))" "${hosts[$i]}"
done
echo ""

# 3. Loop until the user provides a valid numeric input.
choice=0
while true; do
    read -p "Enter the number of your choice: " input

    # Check if input is a valid number and within the range of available hosts.
    if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le "${#hosts[@]}" ]; then
        choice=$input
        break
    else
        echo "Invalid input. Please enter a number between 1 and ${#hosts[@]}."
    fi
done

# 4. Get the selected host name from the array (adjusting for zero-based index).
selected_host="${hosts[$((choice-1))]}"
echo "You have selected: $selected_host"
echo ""

# 5. Construct the command to be executed.
NIXOS_COMMAND="nixos-rebuild switch --flake .#$selected_host"

# 6. Ask for confirmation before applying the changes.
read -p "Apply this configuration now? (y/n): " confirm

# 7. Act based on the user's confirmation.
#    We check for 'y', 'Y', 'yes', 'Yes', etc. Anything else is treated as 'no'.
case "$confirm" in
    [yY]|[yY][eE][sS])
        echo "Applying NixOS configuration for '$selected_host'. This may take a while..."
        # Execute the command. Since we already checked for root, no 'sudo' is needed here.
        if ! $NIXOS_COMMAND; then
            echo "Error: The NixOS rebuild command failed."
            exit 1
        fi
        echo "Configuration applied successfully."
        ;;
    *)
        echo "Build process aborted by user."
        echo "To apply this configuration later, run the following command from your configuration directory:"
        # Display the command with 'sudo' for user convenience.
        echo "sudo $NIXOS_COMMAND"
        ;;
esac

exit 0