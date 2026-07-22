{ ... }:
{
  keymaps = [
    # Neo-tree file explorer
    {
      mode = "n";
      key = "<leader>e";
      action = ":Neotree toggle<CR>";
      options = {
        desc = "Toggle file explorer";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>o";
      action = ":Neotree focus<CR>";
      options = {
        desc = "Focus file explorer";
        silent = true;
      };
    }

    # Window navigation without the <C-w> prefix
    {
      mode = "n";
      key = "<C-h>";
      action = "<C-w>h";
      options.desc = "Go to left window";
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-w>j";
      options.desc = "Go to lower window";
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-w>k";
      options.desc = "Go to upper window";
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-w>l";
      options.desc = "Go to right window";
    }

    # Buffer (open file tab) navigation
    {
      mode = "n";
      key = "<S-h>";
      action = ":BufferLineCyclePrev<CR>";
      options = {
        desc = "Previous buffer";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<S-l>";
      action = ":BufferLineCycleNext<CR>";
      options = {
        desc = "Next buffer";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>bd";
      action = ":bdelete<CR>";
      options = {
        desc = "Close buffer";
        silent = true;
      };
    }

    # Clear search highlight
    {
      mode = "n";
      key = "<Esc>";
      action = ":nohlsearch<CR>";
      options = {
        desc = "Clear search highlight";
        silent = true;
      };
    }
  ];
}
