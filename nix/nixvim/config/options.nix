{ ... }:
{
  opts = {
    number = true; # Show line numbers
    relativenumber = true; # Show relative line numbers
    shiftwidth = 2; # Tab width should be 2
    expandtab = true; # Spaces instead of tabs

    clipboard = "unnamedplus"; # Yank/paste straight to the macOS clipboard
    undofile = true; # Persistent undo across sessions

    ignorecase = true; # Case-insensitive search...
    smartcase = true; # ...unless the query contains a capital

    scrolloff = 8; # Keep context above/below the cursor
    splitright = true;
    splitbelow = true;
    signcolumn = "yes"; # Stable gutter (gitsigns, diagnostics)
    cursorline = true;
    termguicolors = true;
  };
}
