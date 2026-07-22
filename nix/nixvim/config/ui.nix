{ ... }:
{
  plugins = {
    lualine.enable = true;
    bufferline.enable = true;
    web-devicons.enable = true;

    # Pops up a cheat-sheet of keybindings when you pause after a prefix
    # (e.g. press <Space> and wait). Makes every mapping discoverable.
    which-key = {
      enable = true;
      settings.spec = [
        {
          __unkeyed-1 = "<leader>f";
          group = "Find (Telescope)";
        }
        {
          __unkeyed-1 = "<leader>g";
          group = "Git";
        }
        {
          __unkeyed-1 = "<leader>l";
          group = "LSP";
        }
        {
          __unkeyed-1 = "<leader>b";
          group = "Buffers";
        }
        {
          __unkeyed-1 = "<leader>d";
          group = "Diagnostics";
        }
        {
          __unkeyed-1 = "<leader>m";
          group = "Markdown";
        }
      ];
    };
  };
}
