#!/bin/bash

CONFIG_DIR="$HOME/Nuyul"
CONFIG_FILE="$CONFIG_DIR/script_config.json"
DEFAULT_VENV_NAME="telebots"
DEFAULT_PATH="$HOME/Projects/Nuyul"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

mkdir -p "$CONFIG_DIR"

# Debug : Move here to disable
#    pyenv --version
#    echo -e "${CYAN}Virtual Environment Name: ${MAGENTA}$VENV_NAME${NC}"
#    echo -e "${CYAN}Script Dir: ${MAGENTA}$script_dir${NC}"
#    echo -e "${CYAN}Script File: ${MAGENTA}$script_file${NC}"
#
# You can move the bash in run_script function to disable extra details

run_script() {
    local script_dir=$1
    local script_file=$2
    local pos_x=$3
    local pos_y=$4
    local win_width=$5
    local win_height=$6

    pyenv --version
    echo -e "${CYAN}Virtual Environment Name: ${MAGENTA}$VENV_NAME${NC}"
    echo -e "${CYAN}Script Dir: ${MAGENTA}$script_dir${NC}"
    echo -e "${CYAN}Script File: ${MAGENTA}$script_file${NC}"

    if [[ $script_file == *.py ]]; then
        xfce4-terminal --hold --title "$script_file" --working-directory="$script_dir" -e "bash -c '
        source ~/.bashrc;
        export PATH=\"\$HOME/.pyenv/bin:\$PATH\";
        eval \"\$(pyenv init --path)\";
        eval \"\$(pyenv init -)\";
        pyenv activate $VENV_NAME && echo -e \"${GREEN}Virtual environment $VENV_NAME activated${NC}\" || echo -e \"${RED}Failed to activate virtual environment $VENV_NAME${NC}\";
        python3 $script_file;
        exec bash'" &
    elif [[ $script_file == *.php ]]; then
        xfce4-terminal --hold --title "$script_file" --working-directory="$script_dir" -e "bash -c '
        php $script_file;
        exec bash'" &
    else
        echo -e "${RED}Invalid file extension: $script_file${NC}"
    fi
    sleep 1
    wmctrl -r "$script_file" -e 0,$pos_x,$pos_y,$win_width,$win_height
}

read_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        base_path=$(jq -r '.base_path' "$CONFIG_FILE")
        VENV_NAME=$(jq -r '.venv_name' "$CONFIG_FILE")
        echo -e "${GREEN}----------------------------------------${NC}"
        echo -e "${GREEN}Saved configuration:${NC}"
        echo -e "${GREEN}----------------------------------------${NC}"
        echo -e "${CYAN}Work Dir: ${GREEN}$base_path${NC}"
        echo -e "${CYAN}VENV: ${GREEN}$VENV_NAME${NC}"
        echo -e "You can edit these in /home/Nuyul or ~/Nuyul"
        echo -e "${GREEN}----------------------------------------${NC}"
        echo ""
    else
        echo -e "${YELLOW}No configuration file found.${NC}"
    fi
}

save_config() {
    jq -n --arg base_path "$base_path" --arg venv_name "$VENV_NAME" \
        '{base_path: $base_path, venv_name: $venv_name}' > "$CONFIG_FILE"
    echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
}

get_base_path() {
    if [[ -z "$base_path" ]]; then
        read -p "Enter the base path for the scripts (default: $DEFAULT_PATH): " base_path
        base_path=${base_path:-$DEFAULT_PATH}
        save_config
    fi
}

get_venv_name() {
    if [[ -z "$VENV_NAME" ]]; then
        read -p "Enter the name of the pyenv virtual environment (default: $DEFAULT_VENV_NAME): " VENV_NAME
        VENV_NAME=${VENV_NAME:-$DEFAULT_VENV_NAME}
        save_config
    fi
}

check_pyenv() {
    if ! command -v pyenv >/dev/null 2>&1; then
        echo -e "${RED}Error: pyenv command not found. Make sure pyenv is installed and properly configured.${NC}"
        exit 1
    fi
}

capitalize() {
    echo "$1" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1'
}

echo -e "${RED}========================================${NC}"
echo -e "${WHITE}          Script Runner Utility          ${NC}"
echo -e "${RED}========================================${NC}"
echo -e "${WHITE}This utility allows you to run various bot scripts in new terminal windows (xfce4-terminal).${NC}"
echo -e "${WHITE}Support PHP, Python3 (pyenv), and JS (Soon) extensions.${NC}"
echo -e "${RED}========================================${NC}"
echo ""

# Execute
check_pyenv
read_config
get_base_path
get_venv_name

# Detect dir
declare -A script_paths
extensions=("py" "php" "js")

while IFS= read -r -d '' dir; do
    for ext in "${extensions[@]}"; do
        script_file=$(find "$dir" -maxdepth 1 -name "*.$ext" -print -quit)
        if [[ -n "$script_file" ]]; then
            script_name=$(basename "$dir")
            script_paths["$script_name"]="$script_file"
            break
        fi
    done
done < <(find "$base_path" -mindepth 1 -maxdepth 1 -type d -print0)

# List script
echo -e "${CYAN}Select the scripts to run:${NC}"
i=1
for script in "${!script_paths[@]}"; do
    formatted_script=$(capitalize "$script")
    file_extension="${script_paths[$script]##*.}"
    echo -e "${CYAN}$i - ${MAGENTA}${formatted_script} Bot${NC} (${GREEN}$file_extension${NC})"
    script_options[$i]=$script
    ((i++))
done
echo -e "${CYAN}A - ${MAGENTA}All Scripts${NC}"

echo -e "Press ENTER or CTRL+C to exit."
read -p "Enter your choice (e.g., 1,2,3 or A for all): " choice

# wmctrl
screen_width=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d 'x' -f 1)
screen_height=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d 'x' -f 2)
columns=3
rows=$(((${#script_options[@]} + columns - 1) / columns))
window_width=$((screen_width / columns))
window_height=$((screen_height / rows))

# Execute the witch!
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
