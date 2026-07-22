{ ... }:
{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./ui.nix
    ./editing.nix
    ./neo-tree.nix
    ./telescope.nix
    ./lsp.nix
    ./completion.nix
    ./treesitter.nix
    ./markdown.nix
  ];

  # Color scheme
  colorschemes.catppuccin.enable = true;

  # Set leader key to space
  globals.mapleader = " ";
}
