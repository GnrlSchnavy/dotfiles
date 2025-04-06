{
  # Import all your configuration modules here
  imports = [ ./bufferline.nix ];

  colorschemes.catppuccin.enable = true;
  opts = {
    number = true; # Show line numbers
    relativenumber = true; # Show relative line numbers
    shiftwidth = 2; # Tab width should be 2
  };

  plugins = {
    lualine.enable = true;

    lsp = {
      enable = true;

    };

    telescope = {
      enable = true;
    };

    treesitter = {
      enable = true;
    };
  };

}