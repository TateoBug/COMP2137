#!/bin/bash

DefaultInt=$(ip r s default | awk '{print $5}')
CURHOSTNAME=$(hostname)
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

if [ -n "$NewHostName" ]; then
    if grep -w "$NewHostName" /etc/hosts; then
    verbose "Host Name $NewHostName is already in /etc/hosts"
else 
    verbose "Updating /etc/hosts with $NewHostName"
    sudo sed -i "/^[^ ]\+ $(hostname)$/s/$(hostname)/$NewHostName/" /etc/hosts
    logger "Updated /etc/hosts with new hostname: $NewHostName"
fi
if grep -w "$NewHostName" /etc/hostname; then
    verbose "Host Name $NewHostName is already in /etc/hostname"
else
    verbose "Updating /etc/hostname with $NewHostName"
    verbose "$NewHostName" | sudo tee /etc/hostname > /dev/null
    sudo hostnamectl set-hostname "$NewHostName"
    logger "Updated /etc/hostname and set hostname to: $NewHostName"
  fi
fi

if [ -n "$NewIP" ]; then
    verbose "Updating /etc/hosts with $NewIP"
    sudo sed -i "s/^$(hostname -I | awk '{print $1}')\s\+$(hostname)/$NewIP $(hostname)/" /etc/hosts
    logger "Updated /etc/hosts with new IP: $NewIP"
    
    verbose "Updating the IP address for netplan..."
    sudo sed -i "/$DefaultInt:/,/addresses:/ { s|addresses: .*$|addresses: [ $NewIP/24 ]| }" /etc/netplan/10-lxc.yaml
    logger "Updated netplan configuration with new IP: $NewIP"
fi

if [ -n "$TwoHostEntry" ]; then
    echo "$TwoHostEntry" | sudo tee -a /etc/hosts > /dev/null
    logger "Added new host entry to /etc/hosts: $TwoHostEntry"
fi
