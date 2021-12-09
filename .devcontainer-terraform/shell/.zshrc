# Starship
eval "$(starship init zsh)"

# McFly
eval "$(mcfly init zsh > /dev/null 2>&1)"

#Setup Terraform plugin cache
mkdir -p $HOME/.terraform.d/plugin-cache
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

# Load up the environment vars
source ~/.profile.sh

# Print out the welcome message
source ~/.welcome.sh