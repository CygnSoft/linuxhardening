#!/bin/bash
# CygnSoft hardening script

# Variables
VERSION="1.0.1"
AUTHOR="Daniel Schwan <daniel.schwan@cygnsoft.com>"
CONTACT="CygnSoft <development@cygnsoft.com>"

# Changelog
CHANGELOG="
v 1.0.1:
* Added workaround for low RAM server, because on Rocky 9 no packages can be installed from epel release

v 1.0.0:
* Initial release
"

# Function to display the changelog
display_changelog() {
    echo -e "Changelog:\n$CHANGELOG"
}

# Function to start the hardening process
start_hardening() {
    clear
    echo "Checking if there is enough RAM available"
    echo "Note: Some Linux systems with less or equal 1 GB RAM can't install Packages via epel repo, since it uses a lot of RAM"
    echo ""
    
    # Check if swap is already enabled
    if sudo swapon --show | grep -q /swapfile; then
        echo "Swap is already enabled. Skipping swap creation."
    else
        create_swap() {
            echo "Creating swap file."
            sudo fallocate -l 2G /swapfile
            sudo chmod 600 /swapfile
            sudo mkswap /swapfile
            sudo swapon /swapfile
        }
    
        # Check available RAM
        ram=$(free -m | awk '/^Mem:/{print $2}')
    
        if [[ $ram -le 1024 ]]; then
            echo "Server has 1 GB of RAM or less. Creating swap file"
            create_swap
        else
            echo "Enough RAM (${ram}MB), no SWAP needed."
            read -p "Create it anyway? (y/n): " create_swap_input
            if [[ $create_swap_input =~ ^[yY]$ ]]; then
                create_swap
            else
                echo "Swap creation skipped."
            fi
        fi
    fi
    
    read -p "Installing epel release and figlet. Press any key to continue
    > "
    
    
    # Install figlet
    sudo dnf install -y epel-release
    sudo dnf install -y figlet
    
    read -p "Ready to start. Press any button to continue
    > "
    clear
    
    # Print a figlet welcome message
    figlet "CygnSoft"
    echo "Hardening script"
    echo " v$VERSION"
    echo " Author: $AUTHOR"
    echo " Contact: $CONTACT"
    echo""
    echo "Hardening process begins now."
    echo ""
    
    sleep 1.5
    
    # User interaction
    read -p "Would you like to create a new user? (y/n):
    > " create_user
    if [[ $create_user =~ ^[yY]$ ]]; then
        read -p "Enter the username of the new user: 
        > " new_username
        sudo adduser $new_username
        sudo passwd $new_username
        sudo mkdir -p /home/$new_username/.ssh
        sudo chmod 700 /home/$new_username/.ssh
        sudo ssh-keygen -t rsa -b 4096 -f /home/$new_username/.ssh/id_rsa -N ""
        sudo chown -R $new_username:$new_username /home/$new_username/.ssh
    fi
    read -p "Press any key to continue.
    > "
    
    echo "Checking if firewalld is installed"
    # Check if firewalld is installed
    if ! command -v firewalld &> /dev/null; then
        echo "Firewalld is not installed. Skipping firewall configuration."
    else
        echo "Firewalld detected, hardening now"
        # Set firewall rules
        sudo firewall-cmd --set-default-zone=drop
        sudo firewall-cmd --permanent --add-service=ssh
        sudo firewall-cmd --reload
        sleep 1
    fi
    
    echo "Updating system now. This may take while"
    sleep 1.5
    
    # Update the system
    sudo dnf update -y
    
    # Install and configure Fail2Ban
    echo "Installing fail2ban"
    sleep 1
    sudo dnf install -y fail2ban
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    
    # Disable unnecessary services
    echo "Disabling unnecessary services"
    sleep 1
    sudo systemctl disable telnet
    sudo systemctl disable xinetd
    
    # Configure SSH
    echo "Configure SSH"
    sleep 1
    sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i '/#MaxAuthTries/c\MaxAuthTries 3' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    
    # Enable SELinux
    echo "Enable selinux"
    sleep 1
    sudo setenforce 1
    sudo sed -i 's/SELINUX=disabled/SELINUX=enforcing/' /etc/selinux/config
    
    # Install and configure automatic security updates
    echo "Installing yum-cron and set it up for security updates"
    sleep 1
    sudo dnf install -y yum-cron
    sudo systemctl enable --now yum-cron
    sleep 1
    read -p "Would you like to install usefull software? (y/n):
    (vim, nano, htop)
    > " install_software
    if [[ $install_software =~ ^[yY]$ ]]; then
        echo "installing additional software"
        sleep 1
        sudo dnf install -y vim
        sudo dnf install -y nano
        sudo dnf install -y htop
    else
        echo "No additional software will be installed"
        sleep 1
    fi
    # Additional instructions for the new user
    echo "Hardening process completed."
    echo "Note: A private key is located in the home directory of the new user. It should be deleted immediately. Also, the user should disable Password Authentication in /etc/ssh/sshd_config."
}

# Function to display information about the script
display_info() {
    clear
    echo "CygnSoft Hardening Script"
    echo "Version: $VERSION"
    echo "Author: $AUTHOR"
    echo "Contact: $CONTACT"
    echo ""
    echo "This script is designed to harden your system by applying various security measures."
}

# Function to display menu and handle user input
display_menu() {
    while true; do
        clear
        echo "CygnSoft Hardening Script"
        echo "1. Start Hardening Process"
        echo "2. View Changelog"
        echo "3. Information about the script"
        echo "4. Exit"
        read -p "Please select an option: " choice
        case $choice in
            1)
                start_hardening
                ;;
            2)
                display_changelog
                read -p "Press Enter to return to the menu..."
                ;;
            3)
                display_info
                read -p "Press Enter to return to the menu..."
                ;;
            4)
                echo "Exiting..."
                exit
                ;;
            *)
                echo "Invalid option. Please select again."
                ;;
        esac
    done
}

# Call the function to display the menu
display_menu
