#!/bin/bash

CONFIG_DIR="$HOME/Nuyul"
CONFIG_FILE="$CONFIG_DIR/script_config.json"
SCRIPT_LIST="$CONFIG_DIR/script_list.json"
DEFAULT_PATH="$HOME/Projects/Nuyul"
LOG_FILE="$HOME/Nuyul/update_log.txt"
DEFAULT_VENV_NAME="telebots"
updated_count=0
not_updated_count=0
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

mkdir -p "$CONFIG_DIR"

run_script() {
    local script_dir=$1
    local script_file=$2
    local total_scripts=$3
    local script_id=$4

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

   # Calculate grid layout for multiple scripts
    local screen_width=$(xdpyinfo | awk '/dimensions/{print $2}' | awk -F'x' '{print $1}')
    local screen_height=$(xdpyinfo | awk '/dimensions/{print $2}' | awk -F'x' '{print $2}')
    local grid_cols=3  # Number of columns in the grid
    local grid_rows=2  # Number of rows in the grid
    local grid_width=$((screen_width / grid_cols))  # Width of each grid cell
    local grid_height=$((screen_height / grid_rows))  # Height of each grid cell
    local col=$((($script_id % $grid_cols)))  # Calculate column position in the grid
    local row=$((($script_id / $grid_cols)))  # Calculate row position in the grid
    local pos_x=$((col * grid_width))  # Calculate x position based on column
    local pos_y=$((row * grid_height))  # Calculate y position based on row

    wmctrl -r "$script_file" -e 0,$pos_x,$pos_y,$grid_width,$grid_height
}



backup_and_update() {
    echo "Update log - $(date)" > "$LOG_FILE"
    
    for dir in "${!script_paths[@]}"; do
        local script_dir=$(dirname "${script_paths[$dir]}")
        local backup_dir="$script_dir/.bak"
        mkdir -p "$backup_dir"
        
        for file in "$script_dir"/*; do
            local filename=$(basename "$file")
            if [[ -f "$backup_dir/$filename" ]]; then
                read -p "Backup file $backup_dir/$filename already exists. Overwrite? (y/n): " choice
                if [[ "$choice" == "y" ]]; then
                    cp "$file" "$backup_dir"
                    echo -e "${GREEN}Backup of $filename updated.${NC}"
                else
                    echo -e "${YELLOW}Skipped backup of $filename.${NC}"
                fi
            else
                cp "$file" "$backup_dir"
                echo -e "${GREEN}Backup of $filename created.${NC}"
            fi
        done

        if (cd "$script_dir" && git fetch); then
            echo -e "${GREEN}Fetched updates for $script_dir.${NC}"
            echo "Updated: $script_dir" >> "$LOG_FILE"
            ((updated_count++))
        else
            echo -e "${RED}Failed to fetch updates for $script_dir.${NC}"
            echo "Not updated: $script_dir" >> "$LOG_FILE"
            ((not_updated_count++))
        fi
    done
    
    echo -e "${GREEN}$updated_count directories updated.${NC}"
    echo -e "${RED}$not_updated_count directories not updated.${NC}"
    echo -e "See update log in $LOG_FILE"
}

update_script_list() {
    declare -A script_paths
    extensions=("py" "php" "js")
    script_list=()
    script_id=1

    while IFS= read -r -d '' dir; do
        for ext in "${extensions[@]}"; do
            script_file=$(find "$dir" -maxdepth 1 -name "*.$ext" -print -quit)
            if [[ -n "$script_file" ]]; then
                script_name=$(basename "$dir")
                url=$(cd "$dir" && git config --get remote.origin.url || echo "N/A")
                script_paths["$script_id"]="$script_file"
                script_list+=("{\"id\":\"$script_id\",\"script\":\"$script_name\",\"isWork\":true,\"url\":\"$url\",\"type\":\"$ext\",\"dir\":\"$dir\",\"main\":\"$(basename "$script_file")\"}")
                ((script_id++))
                break
            fi
        done
    done < <(find "$base_path" -mindepth 1 -maxdepth 1 -type d -print0)

    script_list_json=$(printf "%s\n" "${script_list[@]}" | jq -s .)
    echo "$script_list_json" > "$SCRIPT_LIST"
    echo -e "${GREEN}Script list updated and saved to $SCRIPT_LIST${NC}"
}

#list_scripts() {
#    working_scripts=$(jq -r '.[] | select(.isWork == true) | "\(.id) - \(.script) (\(.type) - Good) - \(.url)"' "$SCRIPT_LIST")
 #   not_working_scripts=$(jq -r '.[] | select(.isWork == false) | "\(.id) - \(.script) (\(.type) - Bad) - \(.url)"' "$SCRIPT_LIST")

 #   echo -e "${CYAN}Working Scripts:${NC}"
 #   echo -e "$working_scripts"
  #  echo -e "${CYAN}Not Working Scripts:${NC}"
#}

read_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        base_path=$(jq -r '.base_path' "$CONFIG_FILE")
        VENV_NAME=$(jq -r '.venv_name' "$CONFIG_FILE")
        echo -e "${GREEN}----------------------------------------${NC}"
        echo -e "${GREEN}Saved configuration:${NC}"
        echo -e "${GREEN}----------------------------------------${NC}"
        echo -e "${CYAN}Work Dir: ${GREEN}$base_path${NC}"
        echo -e "${CYAN}VENV: ${GREEN}$VENV_NAME${NC}"
        echo -e "${CYAN}List: ${GREEN}$SCRIPT_LIST${NC}"
        echo -e "You can edit these in $HOME/Nuyul"
        echo -e "${GREEN}----------------------------------------${NC}"
        echo ""
    else
        echo -e "${YELLOW}No configuration file found.${NC}"
    fi

    if [[ -f "$SCRIPT_LIST" ]]; then
        echo -e "${GREEN}Loading list...${NC}"
        script_paths=$(jq -c '.[]' "$SCRIPT_LIST")
    else
        echo -e "${YELLOW}No script list found. Scanning directories...${NC}"
        update_script_list
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

read_config
get_base_path
get_venv_name

echo ""
echo -e "${CYAN}----------------------------------------${NC}"
echo -e "${CYAN}Select the scripts to run:${NC}"
i=1
declare -A script_options
for script in $(jq -r '.[] | .script' "$SCRIPT_LIST"); do
    formatted_script=$(capitalize "$script")
    file_extension=$(jq -r --arg script "$script" '.[] | select(.script == $script) | .type' "$SCRIPT_LIST")
    is_work=$(jq -r --arg script "$script" '.[] | select(.script == $script) | .isWork' "$SCRIPT_LIST")
    status="Bad"
    [[ "$is_work" == "true" ]] && status="Good"
    script_id=$(jq -r --arg script "$script" '.[] | select(.script == $script) | .id' "$SCRIPT_LIST")
    echo -e "${CYAN}$script_id - ${MAGENTA}${formatted_script} Bot${NC} (${GREEN}$file_extension - $status${NC})"
    script_options[$script_id]=$script
    ((i++))
done
echo -e "${CYAN}A - ${MAGENTA}All Scripts${NC}"
echo -e "${CYAN}U - ${MAGENTA}Update Scripts${NC}"
echo -e "${CYAN}L - ${MAGENTA}Update List${NC}"

# Read user input
read -p "Enter your choice: " user_choice

# Process user choice
IFS='.' read -r -a choices <<< "$user_choice"

case $user_choice in
    [Aa])
        total_scripts=${#script_paths[@]}
        for script_id in "${!script_paths[@]}"; do
            script_name=$(jq -r --arg id "$script_id" '.[] | select(.id == $id) | .script' "$SCRIPT_LIST")
            script_dir=$(jq -r --arg id "$script_id" '.[] | select(.id == $id) | .dir' "$SCRIPT_LIST")
            script_file=$(jq -r --arg id "$script_id" '.[] | select(.id == $id) | .main' "$SCRIPT_LIST")
            run_script "$script_dir" "$script_file" $total_scripts $script_id
        done
        ;;
    [Uu])
        backup_and_update
        ;;
    [Ll])
        update_script_list
        ;;
    *)
         total_scripts=${#choices[@]}
        for idx in "${!choices[@]}"; do
            if [[ -n "${script_options[${choices[$idx]}]}" ]]; then
                script_name="${script_options[${choices[$idx]}]}"
                script_dir=$(jq -r --arg id "${choices[$idx]}" '.[] | select(.id == $id) | .dir' "$SCRIPT_LIST")
                script_file=$(jq -r --arg id "${choices[$idx]}" '.[] | select(.id == $id) | .main' "$SCRIPT_LIST")
                run_script "$script_dir" "$script_file" $total_scripts $idx
            else
                echo -e "${RED}Invalid choice: ${choices[$idx]}. Skipping.${NC}"
            fi
        done
        ;;
esac

echo -e "${CYAN}Press E to exit or R to re-run the script.${NC}"
read -p "Enter your choice: " user_action
case $user_action in
    [Ee])
        exit 0
        ;;
    [Rr])
        exec "$0"
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac
