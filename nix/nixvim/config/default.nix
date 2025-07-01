{ pkgs, ... }:
{
  # Import all your configuration modules here
  imports = [ ./bufferline.nix ];

  colorschemes.catppuccin.enable = true;
  
  # Set leader key to space
  globals.mapleader = " ";
  
  opts = {
    number = true; # Show line numbers
    relativenumber = true; # Show relative line numbers
    shiftwidth = 2; # Tab width should be 2
  };

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
              nixos = {
                expr = "(builtins.getFlake \"/Users/yvan/.dotfiles/nix\").nixosConfigurations.m4.options";
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
          "<leader>e" = "open_float";    # Show diagnostic popup
          "<leader>q" = "setloclist";    # Add diagnostics to location list
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

    telescope = {
      enable = true;
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