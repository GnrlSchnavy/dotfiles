{ ... }:
{
  plugins = {
    # In-buffer rendering of headings, checkboxes, tables, code blocks —
    # makes .md files read like a notes app instead of raw markup.
    render-markdown.enable = true;

    # Live preview in the browser (:MarkdownPreviewToggle / <leader>mp)
    markdown-preview.enable = true;
  };

  # Prose-friendly settings for markdown buffers only
  autoCmd = [
    {
      event = "FileType";
      pattern = [ "markdown" ];
      callback.__raw = ''
        function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
          vim.opt_local.spell = true
          vim.opt_local.spelllang = "en"
          vim.opt_local.conceallevel = 2
        end
      '';
    }
  ];

  keymaps = [
    {
      mode = "n";
      key = "<leader>mp";
      action = ":MarkdownPreviewToggle<CR>";
      options = {
        desc = "Markdown preview in browser";
        silent = true;
      };
    }
  ];
}
