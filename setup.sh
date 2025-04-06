curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install

# To use Nixpkgs unstable:
# nix run nix-darwin/master#darwin-rebuild -- switch
# To use Nixpkgs 24.11:
nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch

darwin-rebuild switch --flake ~/.dotfiles/nix#m4 -v
