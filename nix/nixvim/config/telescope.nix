{ ... }:
{
  # Enhanced Telescope - Fuzzy Finder
  plugins.telescope = {
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
}
