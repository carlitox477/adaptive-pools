#!/bin/bash

# Save the current font setting
# current_font=$(gsettings get org.gnome.desktop.interface monospace-font-name)

# Set the terminal font to your desired font
desired_font='Monaco 12'
# gsettings set org.gnome.desktop.interface monospace-font-name "$desired_font"

# Banner
# cat << "EOF"
#       __        __  ___         ___  __   __   __       
#  /\  |  \  /\  |__)  |  | \  / |__  |__) /  \ /  \ |    
# /~~\ |__/ /~~\ |     |  |  \/  |___ |    \__/ \__/ |___ 
                                                        
# EOF

# Banner
cat << "EOF"


      __        __  ___         ___  __   __   __        ____  
 /\  |  \  /\  |__)  |  | \  / |__  |__) /  \ /  \ |    /___ 
/~~\ |__/ /~~\ |     |  |  \/  |___ |    \__/ \__/ |___ ___/ 


EOF
cat << "EOF"

*An adaptive implementation of Uniswap V4 Liquidity Pools via hooks*

EOF


# Your script's functionality here
# For demonstration, we'll replace sleep 5 with your deployment script
DEPLOY_SCRIPT_PATH="./scripts/deploy.s.sol" # Adjust path to your Foundry deployment script
LIQUIDITY_SCRIPT_PATH="./scripts/provide_liquidity.s.sol" # Adjust path for liquidity provision
SWAP_SCRIPT_PATH="./scripts/swap.s.sol" # Adjust path for swap

# Helper function for deploying AdaptivePool
deploy_adaptive_pool() {
    echo "Deploying AdaptivePool..."
    # Add your deployment logic here
}

# Helper function for providing liquidity
provide_liquidity() {
    echo "Providing liquidity..."
    # Add your liquidity provision logic here
}

# Helper function for swapping tokens
swap_tokens() {
    echo "Swapping tokens..."
    # Add your swapping logic here
}

# Main menu for the script
show_menu() {
    echo "Select an operation:"
    echo ""
    echo "1) Deploy an AdaptivePool"
    echo "2) Provide Liquidity to an AdaptivePool"
    echo "3) Swap tokens"
    echo ""
    echo "4) Exit"
    echo ""
    read option

    case $option in
        1) deploy_adaptive_pool ;;
        2) provide_liquidity ;;
        3) swap_tokens ;;
        4) exit 0 ;;
        *) echo "Invalid option selected. Please try again." ;;
    esac
}

# Show the menu until the user chooses to exit
while true; do
    show_menu
done

echo "setting back to $current_font"
# After script execution, reset the font back to the original setting
# gsettings set org.gnome.desktop.interface monospace-font-name "$current_font"
