{ ... }:
{
  plugins = {
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
  };
}
