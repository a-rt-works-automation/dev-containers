# Starship
eval "$(starship init bash)"

# McFly
eval "$(mcfly init bash)"

#Setup Terraform plugin cache
mkdir -p $HOME/.terraform.d/plugin-cache
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

# Print out the welcome message
source ~/.profile.sh

# Print out the welcome message
source ~/.welcome.sh