#!/bin/bash
# Function to fetch the clusters
fetch_clusters() {
    clusters=$(kubectl config get-clusters | tail -n +2) # Skip the header
    IFS=$'\n' read -rd '' -a menu_items <<<"$clusters"
    num_items=${#menu_items[@]}
}

# Function to print the menu
print_menu() {
    tput clear
    echo "---------------------------------------------"
    echo "Current Context: $current_context"
    for i in "${!menu_items[@]}"; do
        if [ $i -eq $current_index ]; then
            # Highlight the selected item
            echo -e "\e[7m${menu_items[$i]}\e[27m"
        else
            echo "${menu_items[$i]}"
        fi
    done
}

# Function to handle key presses
handle_key() {
    case $1 in
        up)
            ((current_index--))
            if [ $current_index -lt 0 ]; then
                current_index=$(($num_items - 1))
            fi
            ;;
        down)
            ((current_index++))
            if [ $current_index -ge $num_items ]; then
                current_index=0
            fi
            ;;
        enter)
            tput rmcup  # Restore the terminal screen
            selected_cluster="${menu_items[$current_index]}"
            echo "Switching to context '$selected_cluster'"
            kubectl config use-context "$selected_cluster"
            exit 0
            ;;
    esac
}

# Save the current screen and disable echoing
tput smcup
stty -echo -icanon

# Fetch the clusters and initialize variables
current_index=0
current_context=$(kubectl config current-context)
fetch_clusters

# Main loop
while true; do
    print_menu

    read -rsn1 input
    if [ "$input" = $'\x1b' ]; then
        read -rsn2 -t 0.1 input
        if [ "$input" = "[A" ]; then
            handle_key up
        elif [ "$input" = "[B" ]; then
            handle_key down
        fi
    elif [ "$input" = "" ]; then
        handle_key enter
    fi
done

# Restore the terminal settings and screen on exit
cleanup() {
    tput rmcup
    stty echo -icanon
}
trap cleanup EXIT
