{ pkgs, ... }:
{
  plugins = {
    treesitter = {
      enable = true;
      nixvimInjections = true;

      # Language parsers - installed via Nix
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        bash
        c
        cpp
        css
        dockerfile
        git_config
        git_rebase
        gitattributes
        gitcommit
        gitignore
        html
        java
        javascript
        json
        kotlin
        lua
        markdown
        markdown_inline
        nix
        python
        rust
        toml
        typescript
        vim
        vimdoc
        xml
        yaml
      ];

      # Enable additional features
      settings = {
        highlight = {
          enable = true;
          additional_vim_regex_highlighting = false;
        };

        indent = {
          enable = true;
        };

        incremental_selection = {
          enable = true;
          keymaps = {
            init_selection = "<C-space>";
            node_incremental = "<C-space>";
            scope_incremental = "<C-s>";
            node_decremental = "<M-space>";
          };
        };
      };
    };

    # Treesitter context - shows current function/class at top
    treesitter-context = {
      enable = true;
      settings = {
        enable = true;
        max_lines = 4;
        min_window_height = 0;
        line_numbers = true;
        multiline_threshold = 20;
        trim_scope = "outer";
        mode = "cursor";
        separator = null;
        zindex = 20;
        on_attach = null;
      };
    };

    # Separate treesitter-textobjects plugin
    treesitter-textobjects = {
      enable = true;
      settings = {
        select = {
          enable = true;
          lookahead = true;
          keymaps = {
            # Functions
            "af" = "@function.outer";
            "if" = "@function.inner";
            # Classes
            "ac" = "@class.outer";
            "ic" = "@class.inner";
            # Parameters/arguments
            "aa" = "@parameter.outer";
            "ia" = "@parameter.inner";
            # Comments
            "aC" = "@comment.outer";
          };
        };

        move = {
          enable = true;
          set_jumps = true;
          goto_next_start = {
            "]m" = "@function.outer";
            "]]" = "@class.outer";
          };
          goto_next_end = {
            "]M" = "@function.outer";
            "][" = "@class.outer";
          };
          goto_previous_start = {
            "[m" = "@function.outer";
            "[[" = "@class.outer";
          };
          goto_previous_end = {
            "[M" = "@function.outer";
            "[]" = "@class.outer";
          };
        };
      };
    };
  };
}
