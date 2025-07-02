{ pkgs, ... }:
{
  # Import existing bufferline config only for now
  imports = [ ./bufferline.nix ];

  # Color scheme
  colorschemes.catppuccin.enable = true;
  
  # Set leader key to space
  globals.mapleader = " ";
  
  opts = {
    number = true; # Show line numbers
    relativenumber = true; # Show relative line numbers
    shiftwidth = 2; # Tab width should be 2
  };

  # Key mappings
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
  ];

  plugins = {
    lualine.enable = true;

    # LSP Configuration
    lsp = {
      enable = true;
      
      # Language servers for your main languages
      servers = {
        # Java development
        jdtls = {
          enable = true;
          settings = {
            java = {
              configuration = {
                runtimes = [
                  {
                    name = "JavaSE-23";
                    path = "${pkgs.zulu23}";
                    default = true;
                  }
                ];
              };
            };
          };
        };
        
        # Kotlin
        kotlin_language_server = {
          enable = true;
        };
        
        # Nix
        nixd = {
          enable = true;
          settings = {
            nixpkgs = {
              expr = "import <nixpkgs> { }";
            };
            options = {
              darwin = {
                expr = "(builtins.getFlake \"/Users/yvan/.dotfiles/nix\").darwinConfigurations.m4.options";
              };
            };
          };
        };
        
        # TypeScript/JavaScript
        ts_ls = {
          enable = true;
        };
        
        # Python
        pyright = {
          enable = true;
        };
        
        # Rust
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
        };
        
        # JSON
        jsonls = {
          enable = true;
        };
        
        # YAML
        yamlls = {
          enable = true;
        };
        
        # Markdown
        marksman = {
          enable = true;
        };
        
        # Docker
        dockerls = {
          enable = true;
        };
        
        # Bash
        bashls = {
          enable = true;
        };
      };
      
      # LSP keymaps
      keymaps = {
        silent = true;
        lspBuf = {
          "gd" = "definition";           # Go to definition
          "gr" = "references";           # Find references
          "gt" = "type_definition";      # Go to type definition
          "gi" = "implementation";       # Go to implementation
          "K" = "hover";                 # Show documentation
          "<leader>rn" = "rename";       # Rename symbol
          "<leader>ca" = "code_action";  # Code actions
        };
        diagnostic = {
          "[d" = "goto_prev";            # Previous diagnostic
          "]d" = "goto_next";            # Next diagnostic
          "<leader>de" = "open_float";   # Show diagnostic popup
          "<leader>dq" = "setloclist";   # Add diagnostics to location list
        };
      };
    };

    # Auto-completion
    cmp = {
      enable = true;
      settings = {
        snippet = {
          expand = "function(args) require('luasnip').lsp_expand(args.body) end";
        };
        
        mapping = {
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-e>" = "cmp.mapping.abort()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = "cmp.mapping(function(fallback) if cmp.visible() then cmp.select_next_item() else fallback() end end, {'i', 's'})";
          "<S-Tab>" = "cmp.mapping(function(fallback) if cmp.visible() then cmp.select_prev_item() else fallback() end end, {'i', 's'})";
        };
        
        sources = [
          { name = "nvim_lsp"; }         # LSP completions
          { name = "luasnip"; }          # Snippet completions
          { name = "buffer"; }           # Buffer completions
          { name = "path"; }             # Path completions
        ];
        
        formatting = {
          format = "function(entry, vim_item) vim_item.menu = ({nvim_lsp = '[LSP]', luasnip = '[Snippet]', buffer = '[Buffer]', path = '[Path]'})[entry.source.name]; return vim_item end";
        };
      };
    };

    # Snippet engine (required for cmp)
    luasnip = {
      enable = true;
    };

    # Enhanced Telescope - Fuzzy Finder
    telescope = {
      enable = true;
      
      # Telescope extensions
      extensions = {
        fzf-native = {
          enable = true;
          settings = {
            fuzzy = true;
            override_generic_sorter = true;
            override_file_sorter = true;
            case_mode = "smart_case";
          };
        };
        file-browser = {
          enable = true;
          settings = {
            theme = "ivy";
            hijack_netrw = true;
          };
        };
      };
      
      settings = {
        defaults = {
          prompt_prefix = "🔍 ";
          selection_caret = "➤ ";
          path_display = [ "truncate" ];
          file_ignore_patterns = [
            "^.git/"
            "node_modules"
            "*.pyc"
            "__pycache__"
            "*.class"
            "target/"
            "build/"
            "dist/"
            ".DS_Store"
          ];
          layout_strategy = "horizontal";
          layout_config = {
            horizontal = {
              prompt_position = "top";
              preview_width = 0.55;
              results_width = 0.8;
            };
            vertical = {
              mirror = false;
            };
            width = 0.87;
            height = 0.80;
            preview_cutoff = 120;
          };
          sorting_strategy = "ascending";
          winblend = 0;
          border = true;
          borderchars = [ "─" "│" "─" "│" "╭" "╮" "╯" "╰" ];
          color_devicons = true;
          use_less = true;
          set_env = {
            COLORTERM = "truecolor";
          };
        };
        
        pickers = {
          find_files = {
            find_command = [ "rg" "--files" "--hidden" "--glob" "!**/.git/*" ];
          };
          live_grep = {
            additional_args = [ "--hidden" ];
          };
          grep_string = {
            additional_args = [ "--hidden" ];
          };
          git_files = {
            show_untracked = true;
          };
        };
      };
      
      keymaps = {
        # File finding
        "<leader>ff" = "find_files";
        "<leader>fg" = "live_grep";
        "<leader>fw" = "grep_string";
        "<leader>fb" = "buffers";
        "<leader>fh" = "help_tags";
        "<leader>fr" = "oldfiles";
        "<leader>fc" = "colorscheme";
        "<leader>fk" = "keymaps";
        "<leader>fd" = "file_browser";
        
        # Git integration
        "<leader>gf" = "git_files";
        "<leader>gs" = "git_status";
        "<leader>gc" = "git_commits";
        "<leader>gb" = "git_branches";
        
        # LSP integration
        "<leader>ld" = "lsp_definitions";
        "<leader>lr" = "lsp_references";
        "<leader>ls" = "lsp_document_symbols";
        "<leader>lw" = "lsp_workspace_symbols";
        "<leader>li" = "lsp_implementations";
        "<leader>lt" = "lsp_type_definitions";
        "<leader>le" = "diagnostics";
      };
    };

    # File Explorer
    neo-tree = {
      enable = true;
      closeIfLastWindow = true;
      window = {
        width = 30;
        autoExpandWidth = false;
      };
      filesystem = {
        filteredItems = {
          hideDotfiles = false;
          hideGitignored = false;
          hideHidden = false;
        };
        followCurrentFile = {
          enabled = true;
          leaveDirsOpen = false;
        };
        useLibuvFileWatcher = true;
      };
      buffers = {
        followCurrentFile = {
          enabled = true;
          leaveDirsOpen = false;
        };
      };
    };

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
        setJumps = true;
        gotoNextStart = {
          "]m" = "@function.outer";
          "]]" = "@class.outer";
        };
        gotoNextEnd = {
          "]M" = "@function.outer";
          "][" = "@class.outer";
        };
        gotoPreviousStart = {
          "[m" = "@function.outer";
          "[[" = "@class.outer";
        };
        gotoPreviousEnd = {
          "[M" = "@function.outer";
          "[]" = "@class.outer";
        };
      };
    };
  };
}