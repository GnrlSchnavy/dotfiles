{ flakePath, darwinHost, ... }:
{
  # LSP Configuration
  plugins.lsp = {
    enable = true;

    # Language servers for your main languages
    servers = {
      # Java development. Runtime auto-discovered from JAVA_HOME
      # (set by jenv via .zshrc) — no hardcoded JDK path here.
      jdtls = {
        enable = true;
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
              expr = "(builtins.getFlake \"${flakePath}\").darwinConfigurations.${darwinHost}.options";
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
}
