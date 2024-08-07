#!/bin/bash

DefaultInt=$(ip r s default | awk '{print $5}')

# Trap signals to prevent the script from being terminated by TERM, HUP, or INT signals
trap '' TERM HUP INT


# Parse command-line options
VERBOSE=false # Reset verbose mode to false initially
while [[ $# -gt 0 ]]; do # Loop through all command-line arguments
    case $1 in
        -verbose) # If the -verbose option is provided
            VERBOSE=true # Enable verbose mode
            ;;
        -name) # If the -name option is provided
            if [[ -n "$2" ]]; then # Check if the next argument is non-empty
                # Assign the next argument to NewHostName
                NewHostName="$2" 
                shift  # Move to the next argument
            else
                echo "Error: -name requires a value" # Print an error message
                exit 1  # Exit the script with an error status
            fi
            ;;
        -ip)
            if [[ -n "$2" ]]; then # Check if the next argument is non-empty
                NewIP="$2" # Assign the next argument to NewIP
                shift # Move to the next argument
            else
                echo "Error: -ip requires a value"
                exit 1
            fi
            ;;
        -hostentry)
            if [[ -n "$2" && -n "$3" ]]; then # Check if the next two arguments are non-empty
                TwoHostEntry="$2 $3"  # Assign the next two arguments to TwoHostEntry
                shift 2 # Move to the next argument
            else
                echo "Error: -hostentry requires two values"
                exit 1
            fi
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
         esac
    shift
done

verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "$1"
    fi
}

if [ -z "$NewHostName" ]; then
    echo "NewHostName is empty"
    exit
else
if grep -w "$NewHostName" /etc/hosts; then
    verbose "Host Name $NewHostName is already in /etc/hosts"
else 
    verbose "Updating /etc/hosts with $NewHostName"
    sudo sed -i "s/\<$(hostname)\>/$NewHostName/" /etc/hosts
fi
fi
if grep -w "$NewHostName" /etc/hostname; then
    verbose "Host Name $NewHostName is already in /etc/hostname"
else
    verbose "Updating /etc/hostname with $NewHostName"
    verbose "$NewHostName" | sudo tee /etc/hostname > /dev/null
    sudo hostnamectl set-hostname "$NewHostName"
   
fi

if [ -n "$NewIP" ]; then
    # apply the newip
    if grep -q $(hostname -I | awk '{print $1}') "/etc/hosts"; then
    verbose "The IP address $(hostname -I | awk '{print $1}') is found in /etc/hosts."
    #else
    #sudo sed -i "s/^[^ ]*  $Hostname/$NewIP  $Hostname/" /etc/hosts
    fi
fi
if grep -A 2 "$DefaultInt:" /etc/netplan/10-lxc.yaml | grep -q "addresses:"; then
    verbose "Updating the IP address for netplan..."
    sudo sed -i "\|"$DefaultInt:"|,\|^ *[^ ]| { \|addresses:| s|addresses: .*$|addresses: [ "$NewIP" ]| }" /etc/netplan/10-lxc.yaml
fi

if [ -n "$TwoHostEntry" ]; then
    verbose "$TwoHostEntry" | sudo tee -a /etc/hosts
fi
