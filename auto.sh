#!/bin/bash

# Configuration directory and file path
CONFIG_DIR="$HOME/Nuyul"
CONFIG_FILE="$CONFIG_DIR/script_config.json"
# Default name of the pyenv virtual environment
DEFAULT_VENV_NAME="telebots"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure the configuration directory exists
mkdir -p "$CONFIG_DIR"

# Function to run a script in a new terminal
run_script() {
    local script_name=$1
    local script_file=$2
    local position_x=$3
    local position_y=$4
    local width=$5
    local height=$6

    # Debugging: Print the current PATH to check if pyenv is in the path
    # echo "Current PATH: $PATH"

    # Debugging: Print the current pyenv version to ensure it's available
    pyenv --version

    # Debugging: Print the virtual environment name to ensure it's set correctly
    echo -e "${CYAN}Virtual Environment Name: ${MAGENTA}$VENV_NAME${NC}"

    # Debugging: Print the script_name and script_file for verification
    echo -e "${CYAN}Script Name: ${MAGENTA}$script_name${NC}"
    echo -e "${CYAN}Script File: ${MAGENTA}$script_file${NC}"

    # Run the script with necessary environment setup
    xfce4-terminal --hold --title "$script_file" --working-directory="$script_name" -e "bash -c '
    source ~/.bashrc;
    export PATH=\"\$HOME/.pyenv/bin:\$PATH\";
    eval \"\$(pyenv init --path)\";
    eval \"\$(pyenv init -)\";
    pyenv activate $VENV_NAME && echo -e \"${GREEN}Virtual environment $VENV_NAME activated${NC}\" || echo -e \"${RED}Failed to activate virtual environment $VENV_NAME${NC}\";
    python3 $script_file;
    exec bash'" &
    
    # Give the terminal some time to open
    sleep 1
    
    # Move and resize the terminal window to the desired position and size
    wmctrl -r "$script_file" -e 0,$position_x,$position_y,$width,$height
}

# Function to read the configuration from the JSON file
read_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        base_path=$(jq -r '.base_path' "$CONFIG_FILE")
        VENV_NAME=$(jq -r '.venv_name' "$CONFIG_FILE")
        echo -e "${GREEN}----------------------------------------${NC}"
        echo -e "${GREEN}Saved configuration:${NC}"
        echo -e "${GREEN}----------------------------------------${NC}"
        echo -e "${CYAN}Work Dir: ${GREEN}$base_path${NC}"
        echo -e "${CYAN}VENV: ${GREEN}$VENV_NAME${NC}"
        echo -e "${GREEN}----------------------------------------${NC}"
        echo ""
    else
        echo -e "${YELLOW}No configuration file found.${NC}"
    fi
}

# Function to save the configuration to the JSON file
save_config() {
    jq -n --arg base_path "$base_path" --arg venv_name "$VENV_NAME" \
        '{base_path: $base_path, venv_name: $venv_name}' > "$CONFIG_FILE"
    echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
}

# Function to get the base path from the user if not set
get_base_path() {
    if [[ -z "$base_path" ]]; then
        read -p "Enter the base path for the scripts (default: $DEFAULT_PATH): " base_path
        base_path=${base_path:-$DEFAULT_PATH}
        save_config
    fi
}

# Function to get the virtual environment name from the user if not set
get_venv_name() {
    if [[ -z "$VENV_NAME" ]]; then
        read -p "Enter the name of the pyenv virtual environment (default: $DEFAULT_VENV_NAME): " VENV_NAME
        VENV_NAME=${VENV_NAME:-$DEFAULT_VENV_NAME}
        save_config
    fi
}

# Check if pyenv is available
check_pyenv() {
    if ! command -v pyenv >/dev/null 2>&1; then
        echo -e "${RED}Error: pyenv command not found. Make sure pyenv is installed and properly configured.${NC}"
        exit 1
    fi
}

# Function to capitalize the first letter of each word in a string
capitalize() {
    echo "$1" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1'
}

# Introduction and description
echo -e "${RED}========================================${NC}"
echo -e "${WHITE}          Script Runner Utility          ${NC}"
echo -e "${RED}========================================${NC}"
echo -e "${WHITE}This utility allows you to run various bot scripts in new terminal windows.${NC}"
echo -e "${RED}========================================${NC}"
echo ""

# Check if pyenv is available
check_pyenv

# Get the default path
DEFAULT_PATH="$HOME/Projects/Nuyul"

# Read the existing configuration if available
read_config

# Get the base path from the user if not set
get_base_path

# Get the virtual environment name from the user if not set
get_venv_name

# Dynamically detect scripts in the base path
declare -A script_paths
while IFS= read -r -d '' dir; do
    script_file=$(find "$dir" -maxdepth 1 -name '*.py' -print -quit)
    if [[ -n "$script_file" ]]; then
        script_name=$(basename "$dir")
        script_paths["$script_name"]="$script_file"
    fi
done < <(find "$base_path" -mindepth 1 -maxdepth 1 -type d -print0)

# Display script options
echo -e "${CYAN}Select the scripts to run:${NC}"
i=1
for script in "${!script_paths[@]}"; do
    formatted_script=$(capitalize "$script")
    echo -e "${CYAN}$i - ${MAGENTA}${formatted_script} Bot${NC}"
    script_options[$i]=$script
    ((i++))
done
echo -e "${CYAN}A - ${MAGENTA}All Scripts${NC}"

# Prompt for user choice
read -p "Enter your choice (e.g., 10,1,5,8,15 or A for all): " choice

# Calculate positions and sizes for the windows
screen_width=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d 'x' -f 1)
screen_height=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d 'x' -f 2)
columns=3
rows=$(((${#script_options[@]} + columns - 1) / columns))
window_width=$((screen_width / columns))
window_height=$((screen_height / rows))

# Run selected scripts
IFS=',' read -r -a selected_scripts <<< "$choice"
counter=0
for i in "${selected_scripts[@]}"; do
    if [[ $i == "A" || $i == "a" ]]; then
        echo -e "${GREEN}Running all scripts...${NC}"
        for script in "${!script_paths[@]}"; do
            row=$((counter / columns))
            col=$((counter % columns))
            x=$((col * window_width))
            y=$((row * window_height))
            run_script "$(dirname "${script_paths[$script]}")" "$(basename "${script_paths[$script]}")" $x $y $window_width $window_height
            ((counter++))
        done
        break
    elif [[ -n "${script_options[$i]}" ]]; then
        script=${script_options[$i]}
        echo -e "${GREEN}Running ${MAGENTA}$(capitalize "$script") Bot...${NC}"
        row=$((counter / columns))
        col=$((counter % columns))
        x=$((col * window_width))
        y=$((row * window_height))
        run_script "$(dirname "${script_paths[$script]}")" "$(basename "${script_paths[$script]}")" $x $y $window_width $window_height
        ((counter++))
    else
        echo -e "${RED}Invalid option: $i${NC}"
    fi
done
